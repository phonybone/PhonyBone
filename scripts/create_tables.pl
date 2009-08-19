#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use PhonyBone::Relational;
use PhonyBone::FileUtilities qw(dir);

# Call create_table on every class in the PhonyBone hiearchy that inherits from PhonyBone::Relational
# How to call:
# perl create_tables.pl 

use Options;
BEGIN: {
  Options::use(qw(d h v drop_first filter=s));
    Options::useDefaults(filter=>'.');
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
}

MAIN: {
    my @classes=get_classes();
    warn "classes are ",Dumper(\@classes) if $ENV{DEBUG};
    foreach my $class (@classes) {
	eval "require $class";
	do {warn "errors loading $class\n",($ENV{DEBUG}?$@:''); next} if $@;
	next if $class eq 'PhonyBone::Relational';
	eval {$class->tablename}; next if $@;
#	next unless $class->can('tablename') && $class->tablename;
	my $coderef=$class->can('create_table');
	next unless ref $coderef eq 'CODE';
	warn "creating tables for $class\n" if $options{d}||$options{v};
	unless ($options{d}) {
	    local $ENV{DEBUG}=1 if $options{v};
	    eval {$class->create_table(drop_first=>$options{drop_first});};
	    warn $@ if $@;
	    warn "$class: shazam!\n" unless $@ || $options{v};
	}
    }
}

# find every package under PhonyBone::Relational
sub get_classes {
    if (@ARGV) { return wantarray? @ARGV:\@ARGV }

    my $relational_file=$INC{'PhonyBone/Relational.pm'} or die "Relational not in \%INC???";
    my $root_dir=dir($relational_file);
    die "'$root_dir' not a readable directory??? ($!)" unless -d $root_dir && -r $root_dir;
    my $regex=$options{filter};
    my @files=grep /$regex/, split(/\n/,`find $root_dir -name '*.pm'`);
    foreach my $class (@files) {
	$class=~s/.*PhonyBone\//PhonyBone::/;
	$class=~s/\//::/gxs;
	$class=~s/\.pm//;
    }

    wantarray? @files:\@files;
}
