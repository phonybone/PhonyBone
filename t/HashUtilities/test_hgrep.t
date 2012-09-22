#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../..");
our $class='PhonyBone::HashUtilities';
use PhonyBone::HashUtilities qw(hgrep);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub test_simple_regex {
    my %h=(this=>'that',
	   these=>'those',
	   something=>'else',
	   fred=>'wilma',
	   barney=>'betty');

    my %h2=hgrep(%h, qr/^th/);
    my (%expected, @correct);
    @correct=qw(this these);
    @expected{@correct}=@h{@correct};
    while (my ($k,$v)=each %expected) {
	cmp_ok ($h2{$k}, 'eq', $expected{$k}, "got $k=>$v");
    }

    %h2=hgrep(\%h, qr/wilma|betty/);
    %expected=();
    @correct=qw(fred barney);
    @expected{@correct}=@h{@correct};
    while (my ($k,$v)=each %expected) {
	cmp_ok ($h2{$k}, 'eq', $expected{$k}, "got $k=>$v");
    }
}

sub test_subref {
    my %h=(nt650 => { make=>'honda', class=>'standard', size=>650 },
	   cbr600 => {make=>'honda', class=>'sport', size=>600 },
	   cr250 => {make=>'honda', class=>'offroad', size=>250 },
	   ninja => {make=>'kawasaki', class=>'sport', size=>650 },
	   vulcan => {make=>'kawasaki', class=>'cruiser', size=>1100},
	   sportster => {make=>'harley', class=>'cruiser', size=>883},
	   kdx220 => {make=>'kawasaki', class=>'offroad', size=>220}
	);

    my %h2=hgrep(%h, sub {$_[1]->{class} eq 'offroad'});
    my @correct=qw(cr250 kdx220);
    my %expected;
    @expected{@correct}=@h{@correct};
    while (my ($k,$v)=each %expected) {
	is_deeply ($h2{$k}, $expected{$k}, "got $k");
    }
	   
    %h2=hgrep(%h, sub {$_[1]->{size} > 500});
    @correct=qw(nt650 cbr600 ninja vulcan sportster);
    %expected=();
    @expected{@correct}=@h{@correct};
    while (my ($k,$v)=each %expected) {
	is_deeply ($h2{$k}, $expected{$k}, "got $k");
    }
	   
    
}

sub main {
    require_ok($class);
    test_simple_regex();
    test_subref();
}

main(@ARGV);

