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
our $class='PhonyBone::FileIterator';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    test_basic($class);
    test_bad_file($class);
}

sub test_basic {
    my ($class)=@_;
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my $fi=$class->new("$Bin/sample.txt");
    isa_ok($fi, $class, "got a $class");

    my @lines;
    while ($fi->has_next) {
	my $line=$fi->next;
	chomp $line;
	push @lines, $line;
    }

    open (FODDER, "$Bin/sample.txt") or die "Can't open sample.txt: $!\n";
    my @expected;
    while (<FODDER>) {
	chomp;
	push @expected, $_;
    }
    close FODDER;

    cmp_ok(scalar @lines, '==', scalar @expected) or BAIL_OUT("number of lines don't match");
    foreach my $line (@lines) {
	my $expected=shift @expected;
	cmp_ok($line, 'eq', $expected);
    }
    
}

sub test_bad_file {
    my ($class)=@_;
    my $fi=eval{$class->new('imaginary.txt')};
    cmp_ok($@, 'eq', "Can't open imaginary.txt: No such file or directory\n", "caught non-existant file");
}

main(@ARGV);

