#!/usr/bin/perl
#
# DW::Controller::Shop::Items
#
# This controller is for shop handlers concerned with various item types.
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

package DW::Controller::Shop::Items;

use strict;
use warnings;
use Carp qw/ croak confess /;

use DW::Controller;
use DW::Pay;
use DW::Routing;
use DW::Shop;
use DW::Template;
use LJ::JSON;
use DW::FormErrors;

DW::Routing->register_string( '/shop/points',  \&shop_points_handler,  app => 1 );
DW::Routing->register_string( '/shop/icons',   \&shop_icons_handler,   app => 1 );
DW::Routing->register_string( '/shop/renames', \&shop_renames_handler, app => 1 );
DW::Routing->register_string( '/shop/account', \&shop_account_handler, app => 1 );

# handles the shop buy points page
sub shop_points_handler {
    my ( $ok, $rv ) = DW::Controller::Shop::_shop_controller();
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
    my ( $ok, $rv ) = DW::Controller::Shop::_shop_controller();
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

# This is the page where a person can choose to buy a rename token for themselves or for another user.
sub shop_renames_handler {
    my ( $ok, $rv ) = DW::Controller::Shop::_shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $post   = $r->post_args;

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
        remote       => $remote,
        cart_display => $rv->{cart_display},
        date         => DateTime->today,
        formdata     => $post || { username => $GET->{user}, anonymous => ( $remote ? 0 : 1 ) }
    };

    my $errors = DW::FormErrors->new;
    if ( $r->did_post ) {
        my %item_data;
        $item_data{from_userid} = $remote ? $remote->id : 0;

        if ( $post->{for} eq 'self' ) {
            if ( $remote && $remote->is_personal ) {
                $item_data{target_userid} = $remote->id;
            }
            else {
                return error_ml('widget.shopitemoptions.error.notloggedin');
            }
        }
        elsif ( $post->{for} eq 'gift' ) {
            my $target_u   = LJ::load_user( $post->{username} );
            my $user_check = validate_target_user( $target_u, $remote );

            if ( defined $user_check->{error} ) {
                $errors->add( 'username', $user_check->{error} );
            }
            else {
                $item_data{target_userid} = $target_u->id;
            }

        }

        if ( $post->{deliverydate} ) {
            $post->{deliverydate} =~ /(\d{4})-(\d{2})-(\d{2})/;
            my $given_date = DateTime->new(
                year  => $1,
                month => $2,
                day   => $3,
            );

            my $time_check = DateTime->compare( $given_date, DateTime->today );

            if ( $time_check < 0 ) {

                # we were given a date in the past
                $errors->add( 'deliverydate', 'time cannot be in the past' );    #FIXME
            }
            elsif ( $time_check > 0 ) {

                # date is in the future, add it.
                $item_data{deliverydate} = $given_date->date;
            }

        }

        unless ( $errors->exist ) {
            $item_data{anonymous} = 1
                if $post->{anonymous} || !$remote;

            $item_data{reason} = LJ::strip_html( $post->{reason} );

            my ( $rv, $err ) =
                $rv->{cart}
                ->add_item( DW::Shop::Item::Rename->new( cannot_conflict => 1, %item_data ) );

            $errors->add( '', $err ) unless $rv;

            unless ( $errors->exist ) {
                return $r->redirect("$LJ::SITEROOT/shop");
            }
        }

    }

    $vars->{errors} = $errors;

    return DW::Template->render_template( 'shop/renames.tt', $vars );
}

# This is the page where a person can choose to buy a paid account for
# themself, another user, or a new user.
sub shop_account_handler {
    my ( $ok, $rv ) = DW::Controller::Shop::_shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $post   = $r->post_args;
    my $vars;

    my $scope = "/shop/account.tt";

    # let's see what they're trying to do
    my $for = $GET->{for};
    return $r->redirect("$LJ::SITEROOT/shop")
        unless $for && $for =~ /^(?:self|gift|new|random)$/;

    return error_ml("$scope.error.invalidself")
        if $for eq 'self' && ( !$remote || !$remote->is_personal );

    my $account_type = DW::Pay::get_account_type($remote);
    return error_ml("$scope.error.invalidself.perm")
        if $for eq 'self' && $account_type eq 'seed';

    my $post_fields = {};
    my $email_checkbox;
    my $premium_convert;

    if ( $for eq 'random' ) {
        if ( my $username = LJ::ehtml( $GET->{user} ) ) {
            my $randomu = LJ::load_user($username);
            if ( LJ::isu($randomu) ) {
                $vars->{randomu} = $randomu;
            }
            else {
                return $r->redirect("$LJ::SITEROOT/shop");
            }
        }
    }

    if ( $for eq 'self' ) {
        $vars->{paid_status} = DW::Widget::PaidAccountStatus->render;
    }

    my $errors = DW::FormErrors->new;
    if ( $r->did_post ) {

        my %item_data;

        $item_data{from_userid} = $remote ? $remote->id : 0;

        if ( $post->{for} eq 'self' ) {
            if ( $remote && $remote->is_personal ) {
                $item_data{target_userid} = $remote->id;
            }
            else {
                return error_ml('widget.shopitemoptions.error.notloggedin');
            }
        }
        elsif ( $post->{for} eq 'gift' ) {
            my $target_u   = LJ::load_user( $post->{username} );
            my $user_check = validate_target_user( $target_u, $remote );

            if ( defined $user_check->{error} ) {
                $errors->add( 'username', $user_check->{error} );
            }
            else {
                $item_data{target_userid} = $target_u->id;
            }
        }
        elsif ( $post->{for} eq 'random' ) {
            my $target_u;
            if ( $post->{username} eq '(random)' ) {
                $target_u = DW::Pay::get_random_active_free_user();
                return error_ml('widget.shopitemoptions.error.nousers')
                    unless LJ::isu($target_u);
                $item_data{anonymous_target} = 1;
            }
            else {
                $target_u = LJ::load_user( $post->{username} );
            }

            my $user_check = validate_target_user( $target_u, $remote );

            if ( defined $user_check->{error} ) {
                $errors->add( 'username', $user_check->{error} );
            }
            else {
                $item_data{target_userid} = $target_u->id;
                $item_data{random}        = 1;
            }
        }
        elsif ( $post->{for} eq 'new' ) {
            my @email_errors;
            LJ::check_email( $post->{email}, \@email_errors, $post, $post->{email_checkbox} );
            if (@email_errors) {
                $errors->add( 'email', join( ', ', @email_errors ) );
            }
            else {
                $item_data{target_email} = $post->{email};
            }
        }

        if ( $post->{deliverydate} ) {
            $post->{deliverydate} =~ /(\d{4})-(\d{2})-(\d{2})/;
            my $given_date = DateTime->new(
                year  => $1,
                month => $2,
                day   => $3,
            );

            my $time_check = DateTime->compare( $given_date, DateTime->today );

            if ( $time_check < 0 ) {

                # we were given a date in the past
                $errors->add( 'deliverydate', 'time cannot be in the past' );    #FIXME
            }
            elsif ( $time_check > 0 ) {

                # date is in the future, add it.
                $item_data{deliverydate} = $given_date->date;
            }

        }
        unless ( $errors->exist ) {
            $item_data{anonymous} = 1
                if $post->{anonymous} || !$remote;

            $item_data{reason} = LJ::strip_html( $post->{reason} );    # plain text

            # build a new item and try to toss it in the cart.  this fails if there's a
            # conflict or something

            my $item = DW::Shop::Item::Account->new(
                type           => $post->{accttype},
                user_confirmed => $post->{alreadyposted},
                force_spelling => $post->{force_spelling},
                %item_data
            );

            # check for renewing premium as paid
            my $u           = LJ::load_userid( $item ? $item->t_userid : undef );
            my $paid_status = $u ? DW::Pay::get_paid_status($u) : undef;

            if ($paid_status) {
                my $paid_curtype = DW::Pay::type_shortname( $paid_status->{typeid} );
                my $has_premium  = $paid_curtype eq 'premium' ? 1 : 0;

                my $ok = DW::Shop::Item::Account->allow_account_conversion( $u, $item->class );

                if ( $ok && $has_premium && $item->class eq 'paid' && !$post->{prem_convert} ) {

                    # check account expiration date
                    my $exptime = DateTime->from_epoch( epoch => $paid_status->{expiretime} );
                    my $newtime = DateTime->now;

                    if ( my $future_ymd = $item->deliverydate ) {
                        my ( $y, $m, $d ) = split /-/, $future_ymd;
                        $newtime = DateTime->new( year => $y + 0, month => $m + 0, day => $d + 0 );
                    }

                    my $to_day = sub { return $_[0]->truncate( to => 'day' ) };

                    if ( DateTime->compare( $to_day->($exptime), $to_day->($newtime) ) ) {
                        my $months = $item->months;
                        my $newexp = $exptime->clone->add( months => $months );
                        my $paid_d = $exptime->delta_days($newexp)->in_units('days');

                        # FIXME: this should be DW::BusinessRules::Pay::DWS::CONVERSION_RATE
                        my $prem_d = int( $paid_d * 0.7 );

                        my $ml_args =
                            { date => $exptime->ymd, premium_num => $prem_d, paid_num => $paid_d };

                        # but only include date if the logged-in user owns the account
                        delete $ml_args->{date} unless $remote && $remote->has_same_email_as($u);

                        $errors->add( undef, '.error.premiumconvert',          $ml_args );
                        $errors->add( undef, '.error.premiumconvert.postdate', $ml_args )
                            if $ml_args->{date};
                        $vars->{premium_convert} = 1;

                    }
                }
            }

            unless ( $errors->exist ) {

                my ( $rv, $err ) = $rv->{cart}->add_item($item);
                $errors->add( '', $err ) unless $rv;

                unless ( $errors->exist ) {
                    return $r->redirect("$LJ::SITEROOT/shop");
                }
            }
        }

    }

    $vars->{errors} = $errors;

    sub get_opts {
        my $given_item = shift;
        my %month_values;
        foreach my $item ( keys %LJ::SHOP ) {
            if ( $item =~ /^$given_item(\d*)$/ ) {
                my $i = $1 || 1;
                $month_values{$i} = {
                    name   => $item,
                    points => $LJ::SHOP{$item}->[3],
                    price  => "\$" . sprintf( "%.2f", $LJ::SHOP{$item}->[0] ) . " USD"
                };
            }
        }
        return \%month_values;
    }

    $vars->{for}             = $for;
    $vars->{remote}          = $remote;
    $vars->{cart_display}    = $rv->{cart_display};
    $vars->{seed_avail}      = DW::Pay::num_permanent_accounts_available() > 0;
    $vars->{num_perms}       = DW::Pay::num_permanent_accounts_available_estimated();
    $vars->{formdata}        = $post || { username => $GET->{user}, anonymous => };
    $vars->{did_post}        = $r->did_post;
    $vars->{acct_reason}     = DW::Shop::Item::Account->can_have_reason;
    $vars->{premium_convert} = $premium_convert;
    $vars->{email_checkbox}  = $email_checkbox;
    $vars->{get_opts}        = \&get_opts;
    $vars->{date}            = DateTime->today;
    $vars->{allow_convert}   = DW::Shop::Item::Account->allow_account_conversion( $remote, 'paid' );

    return DW::Template->render_template( 'shop/account.tt', $vars );
}

sub validate_target_user {
    my ( $target_u, $remote ) = shift;
    return { error => 'widget.shopitemoptions.error.invalidusername' }
        unless LJ::isu($target_u);

    return { error => 'widget.shopitemoptions.error.expungedusername' }
        if $target_u->is_expunged;

    return { error => 'widget.shopitemoptions.error.banned' }
        if $remote && $target_u->has_banned($remote);

    return { success => 1 };
}

1;
