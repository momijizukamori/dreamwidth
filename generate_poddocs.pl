#!/usr/bin/perl
use strict;
use warnings;
use Pod::ProjectDocs;

my $pd = Pod::ProjectDocs->new(
    libroot => './cgi-bin',
    outroot => './poddocs',
    title   => 'Dreamwidth',
    nosourcecode => 1,
);
$pd->gen();
