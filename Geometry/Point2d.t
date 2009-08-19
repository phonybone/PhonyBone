#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Test::More qw(no_plan);

use Root qw(clone);
use Line2d;
use Point2d;

MAIN: {
    my $class='Point2d';
    my $p=$class->new(x=>2,y=>2);
    $p->normalize;
    is ($p->magnitude,1,'normalize');

    $p=$class->new(x=>rand(38),y=>rand(22));
    $p->normalize;
    is ($p->magnitude,1,'normalize');
}
