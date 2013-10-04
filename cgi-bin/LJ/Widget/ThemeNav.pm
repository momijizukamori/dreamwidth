# This code was forked from the LiveJournal project owned and operated
# by Live Journal, Inc. The code has been modified and expanded by
# Dreamwidth Studios, LLC. These files were originally licensed under
# the terms of the license supplied by Live Journal, Inc, which can
# currently be found at:
#
# http://code.livejournal.org/trac/livejournal/browser/trunk/LICENSE-LiveJournal.txt
#
# In accordance with the original license, this code and all its
# modifications are provided under the GNU General Public License.
# A copy of that license can be found in the LICENSE file included as
# part of this distribution.

package LJ::Widget::ThemeNav;

use strict;
use base qw(LJ::Widget);
use Carp qw(croak);
use LJ::Customize;
use Storable qw/ nfreeze /;

sub ajax { 1 }
sub can_fake_ajax_post { 1 }
sub authas { 1 }
sub need_res { qw( stc/widgets/themenav.css js/6alib/inputcomplete.js ) }

sub render_body {
    my $class = shift;
    my %opts = @_;

    my $u = $class->get_effective_remote();
    die "Invalid user." unless LJ::isu($u);

    my $theme_chooser_id = defined $opts{theme_chooser_id} ? $opts{theme_chooser_id} : 0;
    my $headextra = $opts{headextra};

    my $remote = LJ::get_remote();
    my $getextra = $u->user ne $remote->user ? "?authas=" . $u->user : "";
    my $getsep = $getextra ? "&" : "?";

    # filter criteria
    my $cat = defined $opts{cat} ? $opts{cat} : "";
    my $layoutid = defined $opts{layoutid} ? $opts{layoutid} : 0;
    my $designer = defined $opts{designer} ? $opts{designer} : "";
    my $search = defined $opts{search} ? $opts{search} : "";
    my $page = defined $opts{page} ? $opts{page} : 1;
    my $show = defined $opts{show} ? $opts{show} : 12;
    my $showarg = $show != 12 ? "show=$opts{show}" : "";

    # we want to have "All" selected if we're filtering by layout or designer, or if we're searching
    my $viewing_all = $layoutid || $designer || $search;

    my $theme_chooser = LJ::Widget::ThemeChooser->new( id => $theme_chooser_id );
    $theme_chooser_id = $theme_chooser->{id} unless $theme_chooser_id;
    $$headextra .= $theme_chooser->wrapped_js( page_js_obj => "Customize" ) if $headextra;

    # split categories - with an array, we'll sort when we print.
    my %cats = LJ::Customize->get_cats($u);
    my %cats_sorted;
    my $cat;
        for $cat( keys %cats ) {
            my @cat_split = split(" ", $cat);
            my $key = shift(@cat_split);

            my @value = $cats_sorted{$key} ? ( @{$cats_sorted{$key}}, @cat_split ) : @cat_split;
            $cats_sorted{$key} = \@value;
        }

    my $post = LJ::Widget->post_fields_of_widget("ThemeNav");
    my @query_return;


    if ($post->{advanced_search_submit}) {
                #build our query here aww yeah
            my %query;

            my $postkey;
            foreach $postkey( keys %{$post}) {
                if ($postkey =~ /^match_(.+)$/) {

                    $query{$1} -> {match_type} = $post->{$postkey};
                }

                if ($postkey =~ /^cat_(.+)$/) {
                    my @split = split('_',$1);
                    my $top_cat = shift(@split);

                    my @value = $query{$top_cat} -> {opts} ? ( @{$query{$top_cat} -> {opts}}, @split ) : (@split);
                    $query{$top_cat} -> {opts} = \@value;
                }
            }

        # dispatch this item...
        my $gc = LJ::gearman_client()
            or die "Unable to get gearman client.\n";

        my $arg = nfreeze( \%query );
        my $task = Gearman::Task->new(
            'style_search', \$arg,
            {
                uniq => '-',
                on_complete => sub {
                    my $res = $_[0] or return undef;
                    @query_return = @{ Storable::thaw( $$res ) };
                },
            }
        );

        # setup the task set for gearman
        my $ts = $gc->new_task_set();
        $ts->add_task( $task );
        $ts->wait( timeout => 10 );


        warn LJ::D(\@query_return);
        warn 'query returned!';
    }

    my $ret;
    $ret .= "<h2 class='widget-header'>" . $class->ml('widget.themenav.title') . "</h2>";

    my @keywords = LJ::Customize->get_search_keywords_for_js($u);
    my $keywords_string = join(",", @keywords);
    $ret .= "<script>Customize.ThemeNav.searchwords = [$keywords_string];</script>";

    $ret .= $class->start_form( id => "search_form" );
    $ret .= "<p class='detail theme-nav-search-box'>";
    $ret .= $class->html_text( name => 'search', id => 'search_box', size => 30, raw => "autocomplete='off'" );
    $ret .= " " . $class->html_submit( "search_submit" => $class->ml('widget.themenav.btn.search'), { id => "search_btn" });
    $ret .= "</p>";
    $ret .= $class->end_form;

    $ret .= "<div class='theme-nav-inner-wrapper section-nav-inner-wrapper'>";
    $ret .= "<div class='theme-selector-nav section-nav'>";

    if (scalar %cats_sorted) {
        $ret .= "<div class='theme-nav-separator section-nav-separator'><hr class='hr' /></div>";

        $ret .= $class->start_form( id => "advanced_search_form" );
        $ret .= "<ul class='theme-nav nostyle section-nav'>";
        $ret .= $class->print_cat_list(
            user => $u,
            selected_cat => $cat,
            viewing_all => $viewing_all,
            cat_list => \%cats_sorted,
            getextra => $getextra,
            showarg => $showarg,
        );
        $ret .= "</ul>";
        $ret .= " " . $class->html_submit( "advanced_search_submit" => "Submit", { id => "search_submit_btn" });
        $ret .= $class->end_form;

        $ret .= "<div class='theme-nav-separator section-nav-separator'><hr class='hr' /></div>";
    }

    $ret .= "<ul class='theme-nav-small nostyle section-nav'>";
    $ret .= "<li class='first'><a href='$LJ::SITEROOT/customize/advanced/'>" . $class->ml('widget.themenav.developer') . "</a>";
    my $upsell = LJ::Hooks::run_hook( 'customize_advanced_area_upsell', $u ) || '';
    $ret .= "$upsell</li>";
    $ret .= "</ul>";

    $ret .= "</div>";

    $ret .= "<div class='theme-nav-content section-nav-content'>";
    $ret .= $class->html_hidden({ name => "theme_chooser_id", value => $theme_chooser_id, id => "theme_chooser_id" });
    $ret .= $theme_chooser->render(
        cat => $cat,
        layoutid => $layoutid,
        designer => $designer,
        search => $search,
        page => $page,
        show => $show,
        adv_search => \@query_return,
    );
    $ret .= "</div>";
    $ret .= "</div>";

    return $ret;
}

sub print_cat_list {
    my $class = shift;
    my %opts = @_;

    my $u = $opts{user};
    my %cat_list = %{$opts{cat_list}};

    my %cats = LJ::Customize->get_cats($u);

    my @custom_themes = LJ::S2Theme->load_by_user($opts{user});

    my $ret;
    my $cat;

    for $cat ( sort (keys(%cat_list) )) {
        next if $cat eq "custom" && !@custom_themes;

        my $div_class = "";
#        $div_class .= " on" if
#            ($cat eq $opts{selected_cat}) ||
#            ($cat eq "featured" && !$opts{selected_cat} && !$opts{viewing_all}) ||
#            ($cat eq "all" && $opts{viewing_all});
        $div_class =~ s/^\s//; # remove the first space
        $div_class = " class='$div_class'" if $div_class;

        $ret .= "<div$div_class><div class='$cat category-title'><h3>$cat</h3></div>";
        my $tag;
            if ($cat_list{$cat}){
                for $tag (sort @{ $cat_list{$cat} }) {
                    $ret .= "<div class='tag $tag'>".$class->html_check(
                    name => "cat_"."$cat"."_"."$tag",
                    id => "$cat"."_"."$tag",
                    );
                    $ret .= " <label for='$cat"."_"."$tag'>$tag</label></div>";
                }
            }
        $ret .= "Match items by:"; #FIXME: english-strip
        $ret .= $class->html_select(
        { name => "match_" . $cat,
        id => "match_type",
        selected => "or", },
        qw (and and or or),
    )
    }

    return $ret;
}

sub handle_post {
    my $class = shift;
    my $post = shift;
    my %opts = @_;


}

sub js {
    q [
        initWidget: function () {
            var self = this;

            if ($('search_box')) {
                var keywords = new InputCompleteData(Customize.ThemeNav.searchwords, "ignorecase");
                var ic = new InputComplete($('search_box'), keywords);

                var text = "theme, layout, or designer";
                var color = "#999";
                $('search_box').style.color = color;
                $('search_box').value = text;
                DOM.addEventListener($('search_box'), "focus", function (evt) {
                    if ($('search_box').value == text) {
                        $('search_box').style.color = "";
                        $('search_box').value = "";
                    }
                });
                DOM.addEventListener($('search_box'), "blur", function (evt) {
                    if ($('search_box').value == "") {
                        $('search_box').style.color = color;
                        $('search_box').value = text;
                    }
                });
            }

            // add event listener to the search form
            DOM.addEventListener($('search_form'), "submit", function (evt) { self.filterThemes(evt, "search", $('search_box').value) });

            var filter_links = DOM.getElementsByClassName(document, "theme-nav-cat");

            // add event listeners to all of the category links
            filter_links.forEach(function (filter_link) {
                var evt_listener_added = 0;
                var getArgs = LiveJournal.parseGetArgs(filter_link.href);
                for (var arg in getArgs) {
                    if (!getArgs.hasOwnProperty(arg)) continue;
                    if (arg == "authas" || arg == "show") continue;
                    DOM.addEventListener(filter_link, "click", function (evt) { self.filterThemes(evt, arg, unescape( getArgs[arg] ) ) });
                    evt_listener_added = 1;
                    break;
                }

                // if there was no listener added to a link, add it without any args (for the 'featured' category)
                if (!evt_listener_added) {
                    DOM.addEventListener(filter_link, "click", function (evt) { self.filterThemes(evt, "", "") });
                }
            });
        },
        filterThemes: function (evt, key, value) {
            if (key == "show") {
                // need to go back to page 1 if the show amount was switched because
                // the current page may no longer have any themes to show on it
                Customize.page = 1;
            } else if (key != "page") {
                Customize.resetFilters();
            }

            // do not do anything with a layoutid of 0
            if (key == "layoutid" && value == 0) {
                Event.stop(evt);
                return;
            }

            if (key == "cat") Customize.cat = value;
            if (key == "layoutid") Customize.layoutid = value;
            if (key == "designer") Customize.designer = value;
            if (key == "search") Customize.search = value;
            if (key == "page") Customize.page = value;
            if (key == "show") Customize.show = value;

            this.updateContent({
                method: "GET",
                cat: Customize.cat,
                layoutid: Customize.layoutid,
                designer: Customize.designer,
                search: Customize.search,
                page: Customize.page,
                show: Customize.show,
                theme_chooser_id: $('theme_chooser_id').value
            });

            Event.stop(evt);

            if (key == "search") {
                $("search_btn").disabled = true;
            } else if (key == "page" || key == "show") {
                $("paging_msg_area_top").innerHTML = "<em>Please wait...</em>";
                $("paging_msg_area_bottom").innerHTML = "<em>Please wait...</em>";
            } else {
                Customize.cursorHourglass(evt);
            }
        },
        onData: function (data) {
            Customize.CurrentTheme.updateContent({
                show: Customize.show
            });
            Customize.hideHourglass();
        },
        onRefresh: function (data) {
            this.initWidget();
            Customize.ThemeChooser.initWidget();
        }
    ];
}

1;
