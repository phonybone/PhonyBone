#!/usr/bin/perl -w
# -*-perl-*-
use strict;
use Carp;
use Data::Dumper;
use FindBin;
use Options;
use Test::More qw(no_plan);

use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../../..";
use P1;
use P1a;
use P1b;

use vars qw($class);

BEGIN: {
  Options::use(qw(d));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $class='PhonyBone::Persistable';
}

MAIN: {
    my $p=P1->new(fred=>'fred',wilma=>'wilma');
    isa_ok($p,'P1');
    $p->store;

    # check fetch to see that we got what we stored
    my $p2=P1->new(pid=>$p->pid)->fetch;
    is ($p->p1a->pa_id,$p2->p1a->pa_id);
    is ($p->p1b->pb_id,$p2->p1b->pb_id);
    
    # update p1a, re-fetch p, and see that they're the same
}

