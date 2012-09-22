#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/../..");
our $class='PhonyBone::StringUtilities';

use PhonyBone::StringUtilities qw(full_split);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $str=<<"    STR";
This is a string.
It has this word in it a few times.
This this this!
What is this?
    STR

    my @chunks=full_split($str, qr/(?i-xsm:this)/);
    is (join('', @chunks), $str);

    my $flat_str=$str;
    $flat_str=~s/\n/ /g;
    @chunks=full_split($flat_str, qr/this/);
#    @chunks=full_split($flat_str, qr/(?i-xsm:this)/);
    is (join('', @chunks), $flat_str);
}

main(@ARGV);

