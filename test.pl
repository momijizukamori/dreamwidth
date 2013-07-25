#!/usr/bin/perl
#

use strict;
use lib "$ENV{LJHOME}/extlib/lib/perl5";
use lib "$ENV{LJHOME}/cgi-bin";
BEGIN { require 'ljlib.pl'; }

use Storable qw/ nfreeze /;

my $gc = LJ::gearman_client()
    or die "Unable to get gearman client.\n";

my @query_return;
my $task = Gearman::Task->new(
    'style_search', \nfreeze( {  } ),
    {
        uniq => '-',
        on_complete => sub {
            my $res = $_[0] or return undef;
            @query_return = @{ Storable::thaw( $$res ) };
        },
    }
);

my $ts = $gc->new_task_set();
$ts->add_task( $task );
$ts->wait( timeout => 10 );

warn LJ::D( \@query_return );
