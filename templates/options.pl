#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$Bin/../lib");


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @args=@_;
    my $arg1=shift @args or die usage(qw(arg1));
}

main(@ARGV);

