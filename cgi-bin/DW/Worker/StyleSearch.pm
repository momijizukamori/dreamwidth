use strict;
use lib "$ENV{LJHOME}/extlib/lib/perl5";
use lib "$ENV{LJHOME}/cgi-bin";
BEGIN {
    require "ljlib.pl";
}

use Gearman::Worker;
use LJ::Worker::Gearman;
use Storable;

gearman_decl( 'style_search' => \&style_search );
gearman_work();


sub style_search (
    my %taglist;
    my %query = %PASSED_IN_QUERY;
    my @layoutslist;

    if (cached taglist exists) {
        %taglist = %{cachedtaglistref}
    } else {
        %taglist = get_tag_hash();
        #CACHE THIS????
    }

    #Query form:
    #%query = (
    #    %category = ( $match => and, @opts => ( opt1 opt2 opt3)),
    #    %category2 = ($match => or, @opts => (opt2 opt3)),
    #)

    for my $query_item (keys %query) {
        if ($query{$query_item} -> {match_type} eq "and") {
            my @layoutlist = match_and($query_item, $query{$query_item}->{opts});
            push (@layoutslist, \@layoutlist);
        } elsif ($query{$query_item} -> {match_type} eq "or")
            my @layoutlist = match_or($query_item, $query{$query_item}->{opts});
            push (@layoutslist, \@layoutlist);
        }

    # Run AND match between categories
    my @queried_layouts = match_and(PASS IT SHIT);

    return @queried_layouts;
)


#Build tag hash structure that looks like this:
#%TAG_HASH = (
#    %tagid => [ style, style, style... ],
#    %tagid2 => [ style, style, style... ],
#)


sub get_tag_hash (

    my %taglist;
    my $dbr = LJ::S2::get_s2_reader();

    my $sth = $dbr->prepare("SELECT s.s2lid, k.keyword ".
                            "FROM s2categories s, sitekeywords k ".
                            "WHERE s.kwid=k.kwid");
    $sth->execute();
    die $sth->errstr if $sth->err;
    while (my ($s2lid, $keyword) = $sth->fetchrow_array) {

            my @s2list = $taglist{$keyword} ? ( @{$taglist{$key}}, $s2lid ) : $s2lid;
            $taglist{$keyword} = \@s2list;
    }

    return %taglist;
)


sub match_or (

    my $category;
    my @opts_list;
    my @s2lid_list = @EXISTING_LIST ? @EXISTING_LIST : "";

    while (@opts_list) {
        my $full_cat = $category . " " . shift(@opts_list);

        push (@s2lid_list, (keys $taglist{$full_cat}));
    }

    return @s2lid_list;
)

sub match_and (

    my $category;
    my @opts_list;
    my @s2lid_list = @EXISTING_LIST;

    while (@opts_list) {
        my $full_cat = $category . " " . shift(@opts_list);
        my @cat_list = keys $taglist{$full_cat};
        my @updated_s2lid_list;

        while (@cat_list) {
            if (@s2lid_list) {
                push (@updated_s2lid_list, (grep (@s2lid_list, shift(@cat_list))));
            } else {
                @s2lid_list = shift(@cat_list);
            }

        }
    }

    return @updated_s2lid_list;
)
