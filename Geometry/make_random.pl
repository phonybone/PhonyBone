#!/usr/bin/perl
use strict;
use warnings;

use Options;
Options::use(qw(d n=i v=s s=s));
Options::useDefaults(n=>50, s=>100);
Options::get();

# might want to normalize vectors

my $n=$options{n};
die "Usage: $0 n (n>2)\n" unless $n>2;
my $vector_limit;
if ($vector_limit=$options{v}) {
    die "vector_limit must be a positive simple float value (got $vector_limit)\n" unless
	$vector_limit=~/^\d*\.?\d+$/;
}
my $scale;
if ($scale=$options{s}) {
    die "scale must be a positive simple float value (got $scale)\n" unless
	$scale=~/^\d*\.?\d+$/;
}


my $filename=shift || "test_points$n";
open (FILE, ">$filename") or die "Can't open $filename for writing: $!\n";
while ($n--) {
    printf FILE "%g,%g",rand(2*$scale)-$scale,rand(2*$scale)-$scale;
    if ($vector_limit) {
	printf FILE " %g,%g",rand($vector_limit)-($vector_limit/2),rand($vector_limit)-($vector_limit/2);
    }
    print FILE "\n";
}
close FILE;
warn "$filename written",(defined $vector_limit && ' (with vectors)'),"\n";

