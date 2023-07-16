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
        date         => DateTime->today
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

# This is the page where a person can choose to buy a paid account for
# themself, another user, or a new user.
sub shop_account_handler {
    my ( $ok, $rv ) = DW::Controller::Shop::_shop_controller( anonymous => 1 );
    return $rv unless $ok;

    my $r      = DW::Request->get;
    my $remote = $rv->{remote};
    my $GET    = $r->get_args;
    my $POST   = $r->post_args;
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

    if ( $r->did_post ) {
        my $error;
        my %from_post;

        $post_fields = LJ::Widget::ShopItemOptions->post_fields($POST);

        if ( keys %$post_fields ) {    # make sure the user selected an account type
             # need to do this because all of these form fields are in the BML page instead of in the widget
            LJ::Widget->use_specific_form_fields(
                post   => $POST,
                widget => "ShopItemOptions",
                fields => [
                    qw( for username email deliverydate_mm deliverydate_dd deliverydate_yyyy anonymous reason alreadyposted force_spelling prem_convert )
                ]
            );

            @BMLCodeBlock::errors = ();    # LJ::Widget->handle_post uses this global variable
            eval {
                %from_post = LJ::Widget->handle_post( $POST,
                    'ShopItemOptions' => { email_checkbox => \$email_checkbox } );
            };

            my @errs = map { LJ::ehtml($_) } split "\n", $BMLCodeBlock::errors[0] // '';
            push @errs, $@ if $@;
            if ( $from_post{error} && ( !@errs || $from_post{error} ne 'premium_convert' ) ) {
                push @errs, $from_post{error};
            }
            $error = join "<br>", @errs;

        }
        else {
            $error = LJ::Lang::ml('.error.noselection');
        }

        if ( $error eq 'premium_convert' ) {
            $premium_convert = 1;

            my $ml_args = $from_post{ml_args};
            $vars->{ml_args} = $ml_args;

        }
        elsif ($error) {
            $vars->{errors} = $error;
        }
        else {
            return $r->redirect("$LJ::SITEROOT/shop");
        }
    }

    $vars->{for}             = $for;
    $vars->{remote}          = $remote;
    $vars->{cart_display}    = $rv->{cart_display};
    $vars->{perm_avail}      = DW::Pay::num_permanent_accounts_available() > 0;
    $vars->{formdata}        = $POST || { username => $GET->{user}, anonymous => };
    $vars->{did_post}        = $r->did_post;
    $vars->{acct_reason}     = DW::Shop::Item::Account->can_have_reason;
    $vars->{premium_convert} = $premium_convert;
    $vars->{email_checkbox}  = $email_checkbox;

    return DW::Template->render_template( 'shop/account.tt', $vars );
}

1;
