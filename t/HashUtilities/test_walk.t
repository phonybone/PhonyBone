#!/usr/bin/env perl 
# -*-perl-*-

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../..");
use lib abs_path("$Bin");
use TestWalk;
our $class='PhonyBone::HashUtilities';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my $testwalk=new TestWalk($class);
    $testwalk->test_compiles;
    $testwalk->print_hash();
}

main(@ARGV);

