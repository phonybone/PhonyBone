#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../..");

use Options;			

our $class='PhonyBone::StringUtilities';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    test1();
    test2();
}

sub test {
    my ($s1, $s2, $expected)=@_;
    cmp_ok(PhonyBone::StringUtilities::differ_at($s1, $s2), '==', $expected);
    cmp_ok(PhonyBone::StringUtilities::differ_at($s2, $s1), '==', $expected);
    warn "$s1\n$s2\n";
    warn ' 'x$expected, "^\n";
}

sub test1 {
    my $s1="Now is the time for all god doogs to jump over the lazy country";
    my $s2="Now is the time for all good dogs to jump over the lazy country";
    my $expected=26;
    test($s1, $s2, $expected);
}

sub test2 {
    my $s1="Now is the time f";
    my $s2="Now is the time for all good dogs to jump over the lazy country";
    my $expected=17;
    test($s1, $s2, $expected);
}

main(@ARGV);

