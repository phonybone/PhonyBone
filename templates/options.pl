#!/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

BEGIN: {
  Options::use(qw(d h));
    Options::useDefaults();
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
}

MAIN: {

}
