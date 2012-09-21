#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use File::Spec;
use FindBin;
my ($v,$d,$f)=File::Spec->splitpath("$FindBin::Bin/$0");

opendir(DIR,$d) or die "Can't open dir $d: $!\n";
my @tests=grep /\.t$/, readdir DIR;
closedir DIR;

use TAP::Harness;
my $tap=new TAP::Harness;
$tap->runtests(@tests);

# look for subdirs:
opendir(DIR,$d) or die "Can't open dir $d: $!\n";
my @subdirs=grep /^[^.]/, grep { -d $_ } readdir DIR;
closedir DIR;

foreach my $d (@subdirs) {
    if (-r "$d/run_tests.pl") {
	if (fork) {
	    chdir $d;
	    exec(qw(perl run_tests.pl));
	}
	wait;
    }
}
