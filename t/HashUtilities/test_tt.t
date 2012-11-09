#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);
use Template;
use Template::Stash;

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../..");
use lib abs_path("$Bin");
use TestTT;
our $class='PhonyBone::HashUtilities';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $testcase=TestTT->new($class);
    $testcase->test_compiles();
    $testcase->test_template();
}

main(@ARGV);

