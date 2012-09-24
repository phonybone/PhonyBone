#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../..");
our $class='Person';

use TestPerson;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    $class=$ARGV[0] or die usage(qw(class));
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my $testcase=new TestPerson(class=>$class);
#    $testcase->run_all_tests;
    $testcase->test_basic();
    $testcase->test_unique();
}



main(@ARGV);

