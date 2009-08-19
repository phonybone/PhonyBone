#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use vars qw($class);

BEGIN: {
  Options::use(qw(d));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $class='PhonyBone::OrderedList';
}

MAIN: {
    require_ok($class) or die "errors loading class '$class': $!\n";
}
