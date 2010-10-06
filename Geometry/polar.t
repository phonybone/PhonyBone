#!/bin/env perl
# -*-perl-*-

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use Math::Trig ':pi';

use lib '/users/vcassen/sandbox/perl';
use lib '/users/vcassen/sandbox/perl/PhonyBone';
use PhonyBone::Geometry::Point2d;

use vars qw($class);

BEGIN: {
  Options::use(qw(d h));
    Options::useDefaults();
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
    $class='PhonyBone::Geometry::Polar';
    use_ok($class);
}

MAIN: {
    my $p1=$class->new(r=>1, theta=>pip4);
    isa_ok($p1,$class,"got a $class");
    my $p2=$class->new(r=>2, theta=>pip2);
    isa_ok($p2,$class,"got a $class");

    my @xy1=$p1->xy;
    my $c1=PhonyBone::Geometry::Point2d->new(x=>$xy1[0],y=>$xy1[1]);
    my @xy2=$p2->xy;
    my $c2=PhonyBone::Geometry::Point2d->new(x=>$xy2[0],y=>$xy2[1]);

    printf "dist(p1,p2)=%g\n",$p1->d($p2);
    printf "dist(c1,c2)=%g\n",$c1->distance_to($c2);
    
}
