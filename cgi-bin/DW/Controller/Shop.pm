#!/usr/bin/perl
#
# DW::Controller::Shop
#
# This controller is for shop handlers.
#
# Authors:
#      Mark Smith <mark@dreamwidth.org>
#
# Copyright (c) 2010-2018 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.
#

package DW::Controller::Shop;

use strict;
use warnings;
use Carp qw/ croak confess /;

use DW::Controller;
use DW::Pay;
use DW::Routing;
use DW::Shop;
use DW::Template;
use LJ::JSON;

# routing directions
DW::Routing->register_string( '/shop',                \&shop_index_handler,            app => 1 );
DW::Routing->register_string( '/shop/points',         \&shop_points_handler,           app => 1 );
DW::Routing->register_string( '/shop/icons',          \&shop_icons_handler,            app => 1 );
DW::Routing->register_string( '/shop/transferpoints', \&shop_transfer_points_handler,  app => 1 );
DW::Routing->register_string( '/shop/refundtopoints', \&shop_refund_to_points_handler, app => 1 );
DW::Routing->register_string( '/shop/receipt',        \&shop_receipt_handler,          app => 1 );
DW::Routing->register_string( '/shop/checkout',       \&shop_checkout_handler,         app => 1 );
DW::Routing->register_string( '/shop/history',        \&shop_history_handler,          app => 1 );
DW::Routing->register_string( '/shop/cancel',         \&shop_cancel_handler,           app => 1 );
DW::Routing->register_string( '/shop/cart',           \&shop_cart_handler,             app => 1 );
DW::Routing->register_string( '/shop/randomgift',     \&shop_randomgift_handler,       app => 1 );
DW::Routing->register_string( '/shop/renames',        \&shop_renames_handler,          app => 1 );

# our basic shop controller, this does setup that is unique to all shop
# pages and everybody should call this first.  returns the same tuple as
# the controller method.
sub _shop_controller {
    my %args = (@_);
    my $r    = DW::Request->get;

    # if payments are disabled, do nothing
    unless ( LJ::is_enabled('payments') ) {
        return ( 0, error_ml('shop.unavailable') );
    }

    # if they're banned ...
    if ( my $err = DW::Shop->remote_sysban_check ) {
        return ( 0, DW::Template->render_template( 'error.tt', { message => $err } ) );
    }

    # basic controller setup
    my ( $ok, $rv ) = controller(%args);
    return ( $ok, $rv ) unless $ok;

    # the entire shop uses these files
    LJ::need_res('stc/shop.css');
    LJ::set_active_resource_group('jquery');

    # figure out what shop/cart to use
    $rv->{shop} = DW::Shop->get;
    $rv->{cart} =
        $r->get_args->{newcart} ? DW::Shop::Cart->new_cart( $rv->{u} ) : $rv->{shop}->cart;
    $rv->{cart} =
        $r->get_args->{ordernum}
        ? DW::Shop::Cart->get_from_ordernum( $r->get_args->{ordernum} )
        : $rv->{shop}->cart;

    # populate vars with cart display template
    $rv->{cart_display} = DW::Template->template_string( 'shop/cartdisplay.tt', $rv );

    # call any hooks to do things before we return success
    LJ::Hooks::run_hooks( 'shop_controller', $rv );

    return ( 1, $rv );
}

# handles the shop index page
sub shop_index_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    $rv->{shop_config} = \%LJ::SHOP;

    return DW::Template->render_template( 'shop/index.tt', $rv );
}

# if someone wants to transfer points...
sub shop_transfer_points_handler {
    my ( $ok, $rv ) = _shop_controller();
    return $rv unless $ok;

    my $remote = $rv->{remote};
    my %errs;
    $rv->{errs}       = \%errs;
    $rv->{has_points} = $remote->shop_points;

    my $r = DW::Request->get;
    if ( $r->did_post ) {
        my $args = $r->post_args;
        die "invalid auth\n" unless LJ::check_form_auth( $args->{lj_form_auth} );

        my $u      = LJ::load_user( $args->{foruser} );
        my $points = int( $args->{points} + 0 );

        if ( !$u ) {
            $errs{foruser} = LJ::Lang::ml('shop.item.points.canbeadded.notauser');
            $rv->{can_have_reason} = DW::Shop::Item::Points->can_have_reason;

        }
        elsif (
            my $item = DW::Shop::Item::Points->new(
                target_userid => $u->id,
                from_userid   => $remote->id,
                points        => $points,
                transfer      => 1
            )
            )
        {
            # provisionally create the item to access object methods

            # error check the user
            if ( $item->can_be_added_user( errref => \$errs{foruser} ) ) {
                $rv->{foru} = $u;
                delete $errs{foruser};    # undefined
            }

            # error check the points
            if ( $item->can_be_added_points( errref => \$errs{points} ) ) {

                # remote must have enough points to transfer
                if ( $remote->shop_points < $points ) {
                    $errs{points} = LJ::Lang::ml('shop.item.points.canbeadded.insufficient');
                }
                else {
                    $rv->{points} = $points;
                    delete $errs{points};    # undefined
                }
            }

            # Note: DW::Shop::Item::Points->can_have_reason doesn't check args,
            # but someone will suggest it do so in the future, so let's save time.
            $rv->{can_have_reason} = $item->can_have_reason( user => $u, anon => $args->{anon} );

        }
        else {
            $errs{foruser} = LJ::Lang::ml('shop.item.points.canbeadded.itemerror');
            $rv->{can_have_reason} = DW::Shop::Item::Points->can_have_reason;
        }

        # copy down anon value and reason
        $rv->{anon}   = $args->{anon} ? 1 : 0;
        $rv->{reason} = LJ::strip_html( $args->{reason} );

        # if this is a confirmation page, then confirm if there are no errors
        if ( $args->{confirm} && !scalar keys %errs ) {

            # first add the points to the other person... wish we had transactions here!
            $u->give_shop_points(
                amount => $points,
                reason => sprintf( 'transfer from %s(%d)', $remote->user, $remote->id )
            );
            $remote->give_shop_points(
                amount => -$points,
                reason => sprintf( 'transfer to %s(%d)', $u->user, $u->id )
            );

            my $get_text = sub { LJ::Lang::get_default_text(@_) };

            # send notification to person transferring the points...
            {
                my $reason = $rv->{reason};
                my $vars   = {
                    from     => $remote->display_username,
                    points   => $points,
                    to       => $u->display_username,
                    reason   => $reason,
                    sitename => $LJ::SITENAMESHORT,
                    reason   => $reason,
                };
                my $body =
                      $reason
                    ? $get_text->( 'esn.sentpoints.body.reason',   $vars )
                    : $get_text->( 'esn.sentpoints.body.noreason', $vars );

                LJ::send_mail(
                    {
                        to       => $remote->email_raw,
                        from     => $LJ::ACCOUNTS_EMAIL,
                        fromname => $LJ::SITENAME,
                        subject  => $get_text->(
                            'esn.sentpoints.subject',
                            {
                                sitename => $LJ::SITENAMESHORT,
                                to       => $u->display_username,
                            }
                        ),
                        body => $body,
                    }
                );
            }

            # send notification to person receiving the points...
            {
                my $e = $rv->{anon} ? 'anon' : 'user';
                my $reason =
                    ( $rv->{reason} && $rv->{can_have_reason} )
                    ? $get_text->( "esn.receivedpoints.reason", { reason => $rv->{reason} } )
                    : '';
                my $body = $get_text->(
                    "esn.receivedpoints.$e.body",
                    {
                        user     => $u->display_username,
                        points   => $points,
                        from     => $remote->display_username,
                        sitename => $LJ::SITENAMESHORT,
                        store    => "$LJ::SITEROOT/shop/",
                        reason   => $reason,
                    }
                );

                # FIXME: esnify the notification
                LJ::send_mail(
                    {
                        to       => $u->email_raw,
                        from     => $LJ::ACCOUNTS_EMAIL,
                        fromname => $LJ::SITENAME,
                        subject  => $get_text->(
                            'esn.receivedpoints.subject', { sitename => $LJ::SITENAMESHORT }
                        ),
                        body => $body,
                    }
                );
            }

            # happy times ...
            $rv->{transferred} = 1;

            # else, if still no errors, send to the confirm pagea
        }
        elsif ( !scalar keys %errs ) {
            $rv->{confirm} = 1;
        }

    }
    else {
        if ( my $for = $r->get_args->{for} ) {
            $rv->{foru} = LJ::load_user($for);
        }

        if ( my $points = $r->get_args->{points} ) {
            $rv->{points} = $points + 0
                if $points > 0 && $points <= 5000;
        }

        $rv->{can_have_reason} = DW::Shop::Item::Points->can_have_reason;
    }

    return DW::Template->render_template( 'shop/transferpoints.tt', $rv );
}

# handles the shop buy points page
sub shop_points_handler {
    my ( $ok, $rv ) = _shop_controller();
    return $rv unless $ok;

    my $remote = $rv->{remote};
    my %errs;
    $rv->{errs} = \%errs;

    my $r = DW::Request->get;
    return $r->redirect("$LJ::SITEROOT/shop") unless exists $LJ::SHOP{points};

    if ( $r->did_post ) {
        my $args = $r->post_args;
        die "invalid auth\n" unless LJ::check_form_auth( $args->{lj_form_auth} );

        my $u      = LJ::load_user( $args->{foruser} );
        my $points = int( $args->{points} + 0 );
        my $item;    # provisionally create the item to access object methods

        if ( !$u ) {
            $errs{foruser} = LJ::Lang::ml('shop.item.points.canbeadded.notauser');

        }
        elsif (
            $item = DW::Shop::Item::Points->new(
                target_userid => $u->id,
                from_userid   => $remote->id,
                points        => $points
            )
            )
        {
            # error check the user
            if ( $item->can_be_added_user( errref => \$errs{foruser} ) ) {
                $rv->{foru} = $u;
                delete $errs{foruser};    # undefined
            }

            # error check the points
            if ( $item->can_be_added_points( errref => \$errs{points} ) ) {
                $rv->{points} = $points;
                delete $errs{points};     # undefined
            }

        }
        else {
            $errs{foruser} = LJ::Lang::ml('shop.item.points.canbeadded.itemerror');
        }

        # looks good, add it!
        unless ( keys %errs ) {
            $rv->{cart}->add_item($item);
            return $r->redirect("$LJ::SITEROOT/shop");
        }

    }
    else {
        my $for = $r->get_args->{for};

        if ( !$for || $for eq 'self' ) {
            $rv->{foru} = $remote;
        }
        else {
            $rv->{foru} = LJ::load_user($for);
        }
    }

    return DW::Template->render_template( 'shop/points.tt', $rv );
}

# handles the shop buy icons page
sub shop_icons_handler {
    my ( $ok, $rv ) = _shop_controller();
    return $rv unless $ok;

    my $remote = $rv->{remote};
    my %errs;
    $rv->{errs} = \%errs;

    my $r = DW::Request->get;
    return $r->redirect("$LJ::SITEROOT/shop") unless exists $LJ::SHOP{icons};

    if ( $r->did_post ) {
        my $args = $r->post_args;
        die "invalid auth\n" unless LJ::check_form_auth( $args->{lj_form_auth} );

        my $u     = LJ::load_user( $args->{foruser} );
        my $icons = int( $args->{icons} + 0 );
        my $item;    # provisionally create the item to access object methods

        if ( !$u ) {
            $errs{foruser} = LJ::Lang::ml('shop.item.icons.canbeadded.notauser');

        }
        elsif (
            $item = DW::Shop::Item::Icons->new(
                target_userid => $u->id,
                from_userid   => $remote->id,
                icons         => $icons
            )
            )
        {
            # error check the user
            if ( $item->can_be_added_user( errref => \$errs{foruser} ) ) {
                $rv->{foru} = $u;
                delete $errs{foruser};    # undefined
            }

            # error check the icons
            if ( $item->can_be_added_icons( errref => \$errs{icons} ) ) {
                $rv->{icons} = $icons;
                delete $errs{icons};      # undefined
            }

        }
        else {
            $errs{foruser} = LJ::Lang::ml('shop.item.icons.canbeadded.itemerror');
        }

        # looks good, add it!
        unless ( keys %errs ) {
            $rv->{cart}->add_item($item);
            return $r->redirect("$LJ::SITEROOT/shop");
        }

    }
    else {
        my $for = $r->get_args->{for};

        if ( !$for || $for eq 'self' ) {
            $rv->{foru} = $remote;
        }
        else {
            $rv->{foru} = LJ::load_user($for);
        }
    }

    return DW::Template->render_template( 'shop/icons.tt', $rv );
}

# if someone wants to refund their account back to points
sub shop_refund_to_points_handler {
    my ( $ok, $rv ) = _shop_controller( form_auth => 1 );
    return $rv unless $ok;

    $rv->{status}     = DW::Pay::get_paid_status( $rv->{remote} );
    $rv->{rate}       = DW::Pay::get_refund_points_rate( $rv->{remote} );
    $rv->{type}       = DW::Pay::get_account_type_name( $rv->{remote} );
    $rv->{can_refund} = DW::Pay::can_refund_points( $rv->{remote} );

    if ( $rv->{can_refund} && ref $rv->{status} eq 'HASH' && $rv->{rate} > 0 ) {
        $rv->{blocks} = int( $rv->{status}->{expiresin} / ( 86400 * 30 ) );
        $rv->{days}   = $rv->{blocks} * 30;
        $rv->{points} = $rv->{blocks} * $rv->{rate};
    }

    unless ( $rv->{can_refund} ) {

        # tell them how long they have to wait for their next refund.
        my $last = $rv->{remote}->prop("shop_refund_time");
        $rv->{next_refund} = LJ::mysql_date( $last + 86400 * 30 ) if $last;
    }

    my $r = DW::Request->get;
    return DW::Template->render_template( 'shop/refundtopoints.tt', $rv )
        unless $r->did_post && $rv->{can_refund};

    # User posted, so let's refund them if we can.
    die "Should never get here in a normal flow.\n"
        unless $rv->{points} > 0;

    # This should never expire the user. Let's sanity check that though, and
    # error if they're within 5 minutes of 30 day boundary.
    my $expiretime = $rv->{status}->{expiretime} - ( $rv->{days} * 86400 );
    die "Your account is just under 30 days and can't be converted.\n"
        if $expiretime - time() < 300;

    $rv->{remote}->give_shop_points(
        amount => $rv->{points},
        reason => sprintf( 'refund %d days of %s time', $rv->{days}, $rv->{type} )
    ) or die "Failed to refund points.\n";
    $rv->{remote}->set_prop( "shop_refund_time", time() );
    DW::Pay::update_paid_status( $rv->{remote},
        expiretime => $rv->{status}->{expiretime} - ( $rv->{days} * 86400 ) );

    # This is a hack, so that when the user lands on the page that says they
    # were successful, it updates the number of points they have. It's just a nice
    # visual indicator of success.
    $rv->{shop} = DW::Shop->get;
    $rv->{cart} =
        $r->get_args->{newcart} ? DW::Shop::Cart->new_cart( $rv->{u} ) : $rv->{shop}->cart;
    $rv->{cart_display} = DW::Template->template_string( 'shop/cartdisplay.tt', $rv );

    # Return the OK to the user.
    $rv->{refunded} = 1;
    return DW::Template->render_template( 'shop/refundtopoints.tt', $rv );
}

# view the receipt for a specific order
sub shop_receipt_handler {

    # this doesn't do form handling or state changes, don't need full shop_controller
    my $r = DW::Request->get;
    return $r->redirect("$LJ::SITEROOT/") unless LJ::is_enabled('payments');

    if ( my $err = DW::Shop->remote_sysban_check ) {
        return DW::Template->render_template( 'error.tt', { message => $err } );
    }

    my ( $ok, $rv ) = controller( anonymous => 1 );
    return $rv unless $ok;

    my $args  = $r->get_args;
    my $scope = '/shop/receipt.tt';

    # we don't have to be logged in, but we do need an ordernum passed in
    my $ordernum = $args->{ordernum} // '';

    my $cart = DW::Shop::Cart->get_from_ordernum($ordernum);
    return error_ml("$scope.error.invalidordernum") unless $cart;

    # cart cannot be in open, closed, or checkout state
    my %invalid_state = (
        $DW::Shop::STATE_OPEN     => 1,
        $DW::Shop::STATE_CLOSED   => 1,
        $DW::Shop::STATE_CHECKOUT => 1,
    );
    return $r->redirect("$LJ::SITEROOT/shop/cart") if $invalid_state{ $cart->state };

    # set up variables for template
    my $vars = { cart => $cart };

    $vars->{orderdate} = DateTime->from_epoch( epoch => $cart->starttime );
    $vars->{carttable} = LJ::Widget::ShopCart->render( receipt => 1, cart => $cart );

    return DW::Template->render_template( 'shop/receipt.tt', $vars );
}

# handles the shop checkout page
sub shop_checkout_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $cart  = $rv->{cart};
    my $r     = DW::Request->get;
    my $GET   = $r->get_args;
    my $scope = 'shop/checkout.tt';

    return error_ml("$scope.error.nocart") unless $cart;
    return error_ml("$scope.error.emptycart") unless $cart->has_items;

    # FIXME: if they have a $0 cart, we don't support that yet
    return error_ml("$scope.error.zerocart")
        if $cart->total_cash == 0.00 && $cart->total_points == 0;

    # establish the engine they're trying to use
    my $eng = DW::Shop::Engine->get( $GET->{method}, $cart );
    return error_ml("$scope.error.invalidpaymentmethod")
        unless $eng;

    # set the payment method on the cart
    $cart->paymentmethod( $GET->{method} );

    # redirect to checkout url
    my $url = $eng->checkout_url;
    return $eng->errstr
        unless $url;
    return $r->redirect($url);

}

sub shop_history_handler {
    my ( $ok, $rv ) = _shop_controller();
    return $rv unless $ok;

    my $cart   = $rv->{cart};
    my $r      = DW::Request->get;
    my $remote = $rv->{remote};

    my @carts    = DW::Shop::Cart->get_all( $remote, finished => 1 );
    my @cartrows = map { $_->{date} => DateTime->from_epoch( epoch => $_->starttime ) } @carts;

    return DW::Template->render_template( 'shop/history.tt', { carts => \@carts } );
}

# handles the shop cancel page
sub shop_cancel_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r     = DW::Request->get;
    my $GET   = $r->get_args;
    my $scope = 'shop/cancel.tt';

    my ( $ordernum, $token, $payerid ) = ( $GET->{ordernum}, $GET->{token}, $GET->{PayerID} );
    my ( $cart, $eng );

    # use ordernum if we have it, otherwise use token/payerid
    if ($ordernum) {
        $cart = DW::Shop::Cart->get_from_ordernum($ordernum);
        return error_ml("$scope.error.invalidordernum")
            unless $cart;

        my $paymentmethod = $cart->paymentmethod;
        my $paymentmethod_class =
            'DW::Shop::Engine::' . $DW::Shop::PAYMENTMETHODS{$paymentmethod}->{class};
        $eng = $paymentmethod_class->new_from_cart($cart);
        return error_ml("$scope.error.invalidcart")
            unless $eng;
    }
    else {
        return error_ml("$scope'.error.needtoken")
            unless $token;

        # we can assume paypal is the engine if we have a token
        $eng = DW::Shop::Engine::PayPal->new_from_token($token);
        return error_ml("$scope'.error.invalidtoken")
            unless $eng;

        $cart     = $eng->cart;
        $ordernum = $cart->ordernum;
    }

    # cart must be in open state
    return $r->redirect("$LJ::SITEROOT/shop/receipt?ordernum=$ordernum")
        unless $cart->state == $DW::Shop::STATE_OPEN;

    # cancel payment and discard cart
    if ( $eng->cancel_order ) {
        return $r->redirect("$LJ::SITEROOT/shop?newcart=1");
    }

    return error_ml("$scope.error.cantcancel");

}

# Allows for viewing and manipulating the shopping cart.
sub shop_cart_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $cart   = $rv->{cart};
    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $POST   = $r->post_args;

    my $vars = {
        duplicate   => $GET->{duplicate},
        failed      => $GET->{failed},
        cart_widget => LJ::Widget::ShopCart->render
    };

    if ( $r->did_post() ) {
        my %from_post = LJ::Widget->handle_post( $POST, ('ShopCart') );
        $vars->{error} = $from_post{error} if $from_post{error};

    }
    return DW::Template->render_template( 'shop/cart.tt', $vars );
}

# Gives a person a random active free user that they can choose to purchase a
# paid account for.
sub shop_randomgift_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $POST   = $r->post_args;

    my $type = $GET->{type};
    $type = 'P' unless $type eq 'C';
    my $othertype = $type eq 'P' ? 'C' : 'P';

    if ( $r->did_post() ) {
        my $username = $POST->{username};
        my $u        = LJ::load_user($username);
        if ( LJ::isu($u) ) {
            return $r->redirect("$LJ::SITEROOT/shop/account?for=random&user=$username");
        }
    }

    my $randomu = DW::Pay::get_random_active_free_user($type);

    my $vars = {
        type       => $type,
        othertype  => $othertype,
        randomu    => $randomu,
        mysql_time => \&LJ::mysql_time
    };
    return DW::Template->render_template( 'shop/randomgift.tt', $vars );
}

# This is the page where a person can choose to buy a rename token for themselves or for another user.
sub shop_renames_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $POST   = $r->post_args;

    return $r->redirect("$LJ::SITEROOT/shop")
        unless exists $LJ::SHOP{rename};

    # let's see what they're trying to do
    my $for = $GET->{for};
    return $r->redirect("$LJ::SITEROOT/shop")
        unless $for && $for =~ /^(?:self|gift)$/;

    # ensure they have a user if it's for self
    return error_ml('/shop/renames.tt.error.invalidself')
        if $for eq 'self' && ( !$remote || !$remote->is_personal );

    my $vars = {
        'for'        => $for,
        user         => $GET->{user},
        remote       => $remote,
        cart_display => $rv->{cart_display},
        date         => DateTime->today->date
    };

    if ( $r->did_post ) {
        my $error;
        my $post_fields = LJ::Widget::ShopItemOptions->post_fields($POST);

     # need to do this because all of these form fields are in the BML page instead of in the widget
        LJ::Widget->use_specific_form_fields(
            post   => $POST,
            widget => "ShopItemOptions",
            fields => [
                qw( item for username deliverydate_mm deliverydate_dd deliverydate_yyyy anonymous )]
        );
        my %from_post = LJ::Widget->handle_post( $POST, ('ShopItemOptions') );
        $error = $from_post{error} if $from_post{error};

        if ($error) {
            $vars->{error} = $error;
        }
        else {
            return $r->redirect("$LJ::SITEROOT/shop");
        }
    }

    return DW::Template->render_template( 'shop/renames.tt', $vars );
}

# The page used to confirm a user's order before we finally bill them.
sub shop_confirm_handler {
    my ( $ok, $rv ) = _shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $POST   = $r->post_args;
    my $vars;

    my $scope = "/shop/confirm.tt";

    my ( $ordernum, $token, $payerid ) = ( $GET->{ordernum}, $GET->{token}, $GET->{PayerID} );
    my ( $cart, $eng, $paymentmethod );

    # use ordernum if we have it, otherwise use token/payerid
    if ($ordernum) {
        $cart = DW::Shop::Cart->get_from_ordernum($ordernum);
        return error_ml("$scope.error.invalidordernum")
            unless $cart;

        $paymentmethod = $cart->paymentmethod;
        my $paymentmethod_class =
            'DW::Shop::Engine::' . $DW::Shop::PAYMENTMETHODS{$paymentmethod}->{class};
        $eng = $paymentmethod_class->new_from_cart($cart);
        return error_ml("$scope.error.invalidcart")
            unless $eng;
    }
    else {
        return error_ml("$scope.error.needtoken")
            unless $token;

        # we can assume paypal is the engine if we have a token
        $eng = DW::Shop::Engine::PayPal->new_from_token($token);
        return error_ml("$scope.error.invalidtoken")
            unless $eng;

        $cart          = $eng->cart;
        $ordernum      = $cart->ordernum;
        $paymentmethod = $cart->paymentmethod;
    }

    # cart must be in open/checkout state
    return $r->redirect("$LJ::SITEROOT/shop/receipt?ordernum=$ordernum")
        unless $cart->state == $DW::Shop::STATE_OPEN || $cart->state == $DW::Shop::STATE_CHECKOUT;

    # check email early so we can re-render the form on error
    my ( $email_checkbox, @email_errors );
    if ( $r->did_post && !$cart->userid ) {
        LJ::check_email( $POST->{email}, \@email_errors, $POST, \$email_checkbox );
    }

    if ( $r->did_post && !@email_errors ) {
        if ( $cart->userid ) {
            my $u = LJ::load_userid( $cart->userid );
            $cart->email( $u->email_raw );
        }
        else {
            # email checked above
            $cart->email( $POST->{email} );
        }

        # and now set the state, we're waiting for the user to send us money
        $cart->state($DW::Shop::STATE_CHECKOUT);

        # they want to pay us, yippee!
        my $confirm = $eng->confirm_order;
        return $eng->errstr
            unless $confirm;
        $vars->{confirm} = $confirm;

    }

    if ( !$r->did_post() || @email_errors ) {

        # set the payerid for later
        $eng->payerid($payerid)
            if $payerid;
    }

    $vars->{showform}      = ( !$r->did_post || @email_errors );
    $vars->{email_errors}  = \@email_errors;
    $vars->{cart}          = $cart;
    $vars->{ordernum}      = $ordernum;
    $vars->{email}         = $POST->{email};
    $vars->{widget}        = LJ::Widget::ShopCart->render( confirm => 1, cart => $cart );
    $vars->{paymentmethod} = $paymentmethod;

    return DW::Template->render_template( 'shop/randomgift.tt', $vars );
}

1;
