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
our $class='TimeUtilities';
use PhonyBone::TimeUtilities qw(duration);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    cmp_ok(duration(0), 'eq', '', '<0>');
    cmp_ok(duration(1), 'eq', '1 sec', '1 sec');
    cmp_ok(duration(3), 'eq', '3 secs', '3 secs');
    cmp_ok(duration(73), 'eq', '1 min, 13 secs', '73 secs');
    cmp_ok(duration(603), 'eq', '10 mins, 3 secs', '603 secs');
    cmp_ok(duration(4203), 'eq', '1 hour, 10 mins, 3 secs', '4203 secs');
    cmp_ok(duration(18_603), 'eq', '5 hours, 10 mins, 3 secs', '18_603 secs');
    cmp_ok(duration(105_003), 'eq', '1 day, 5 hours, 10 mins, 3 secs', '105_003 secs');
    cmp_ok(duration(7_017_003), 'eq', '81 days, 5 hours, 10 mins, 3 secs', '7_017_003 secs');
    cmp_ok(duration(38_538_603), 'eq', '1 year, 81 days, 1 hour, 10 mins, 3 secs', '38_538_603 secs');
    cmp_ok(duration(322_377_003), 'eq', '10 years, 81 days, 5 hours, 10 mins, 3 secs', '322_377_003 secs');
}

main(@ARGV);

