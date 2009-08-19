#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

BEGIN: {
  Options::use(qw(d q v h fuse=i I=s));
    Options::useDefaults(fuse => -1, I=>[]);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    push @INC, @{$options{I}};
}

MAIN: {
    my ($class,$id)=@ARGV;
    my $usage="perl thaw.pl <class> <key=id>\n";
    die $usage unless $class && $id;
    eval "require $class" or die $@;

    my ($pri_key,$pri_id)=split('=',$id);
    if (!$pri_id) {
	$pri_id=$pri_key;
	$pri_key=$class->primary_key or confess "no primary_key";
    }
    my $obj=$class->fetch($pri_key=>$pri_id) or die "no $class for '$pri_key=$pri_id'\n";
    warn Dumper($obj);
}
