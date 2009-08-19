#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use FindBin;
use Options;
use Test::More qw(no_plan);

use vars qw($class);

BEGIN: {
  Options::use(qw(d));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    use lib '../..';
    $class='PhonyBone::Relational';
}

MAIN: {
    require_ok($class) or die "errors loading class '$class': $!\n";
    require_ok('SampleTable') or die "quitting\n";;

    # want to define a table, then create it, do some actions against it, and then drop it
    my $st=SampleTable->new;

    isa_ok($st,'SampleTable');
    my $dbh=$st->dbh;
    isa_ok($dbh,'DBI::db', "($dbh)");

    local $ENV{DEBUG}=1;
    $st->create_table(drop_first=>1);
    
}

