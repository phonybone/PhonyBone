#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Data::Dumper;

use Options;

BEGIN: {
  Options::use(qw(d h drop_first I=s));
    Options::useDefaults(drop_first=>1, I=>[]);
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};

    foreach my $dir (@{$options{I}}) {
	push @INC,$dir;
    }
}

MAIN: {
    my $usage="$0 <class>\n";
    foreach my $class (@ARGV) {
	eval "require $class"; die $@ if $@;
	$class->create_table(drop_first=>$options{drop_first});
    }
}
