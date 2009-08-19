#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Math::Combinatorics qw(combine);


# generate all combinations of subsets from a list of elements
# can be slow for values over about 12;
# generates 2^^$n total combinations
sub combinations {
    my $list = shift;
    return [$list] if @$list == 1;

    my $elem = pop @$list;
    my $lists = combinations($list);

    my @newlists;
    foreach my $l (@$lists) {
	my @newlist = @$l;
	push @newlist, $elem;
	push @newlists, \@newlist;
    }
    push @newlists, [$elem];
    push @newlists, @$lists;
    \@newlists;
}

# returns all subsets of size $n of the list.
# calls combinations($list), above, so performance issues remain
sub subsets_old {
    my $list = shift or confess "no lists";
    my $n = shift; confess "no n" unless defined $n;
    confess "$n out of range" if $n<=0 || $n>@$list;
    my $lists = combinations($list);
    my @subsets;
    map { push @subsets, $_ if @$_ == $n } @$lists;
    return \@subsets;
}

sub subsets {
    my $list=shift or confess "no list";
    my $n=shift or confess "no n";
    confess "$n out of range" if $n<=0 || $n>@$list;
    my @ss=combine($n,@$list);
    return wantarray? @ss:\@ss;
}

1;



MAIN: {
    my $n = shift or die "no n\n";
    my $i = shift;
    
    my $lists;
    if (defined $i) {
	$lists = subsets([('a'..$n)], $i);
    } else {
	$lists = combinations([('a'..$n)]);
    }
    foreach my $list (@$lists) {
	warn join(', ', @$list), "\n";
    }
    warn scalar @$lists, ' ', defined $i?'subsets':'combinations',"\n";
}
