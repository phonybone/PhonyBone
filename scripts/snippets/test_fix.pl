#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Options;
use FindBin;
require "$FindBin::Bin/get_files.pl";


BEGIN: {
  Options::use(qw(d h));
    Options::useDefaults();
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
}

MAIN: {
    my $dir=shift || '.';
    $dir=fix($dir);
    warn "final: dir is $dir\n";
}
