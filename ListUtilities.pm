#!/usr/bin/env perl
use strict;
use warnings;

# For things not found in List::Utils, List::MoreUtils, etc.
# (except that some, eg 'end', are)

package PhonyBone::ListUtilities;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(unique_sorted unique all_unique union intersection 
		delete_elements remove keep all_matching
		subtract xor invert soft_copy shuffle 
		is_monotonic_asc is_monotonic_desc min max minmax range end reverse
		split_on_elem array_iterator hash_iterator
		equal_lists in_list
		first_n last_n
		);

use Data::Dumper;
use Carp;


# A few utility list utility routines

# remove redundant elements from a SORTED list:
# nominally faster the unique(), below.
sub unique_sorted {
    my @answer;
    my $last = shift @_ or return ();
    push @answer, $last;	# now put it back

    for (@_) {
	push @answer, $_ unless $_ eq $last;
	$last = $_;
    }
    @answer;
}

# remove redundant elements from a list:
# takes either list of listref; returns either list or listref
sub unique {
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my %hash=map{($_,$_)} @$list;
    wantarray? values %hash : [values %hash];
}

# return 1 if every element in the list is different, 0 otherwise
sub all_unique {
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my %hash;
    foreach my $e (@$list) {
	return 0 if $hash{$e};
	$hash{$e}=$e;
    }
    return 1;
}

# remove elements from a list
# call as "delete_elements(\@list, @to_remove)"
# Don't think it works if list elements are objects, unless maybe they define an 'eq' operator
sub delete_elements {
    my $list_ref = shift;
    my @new_list;
    croak "'$list_ref' not an ARRAY ref" unless ref $list_ref eq 'ARRAY';
    foreach my $item (@$list_ref) {
	push @new_list, $item unless grep { $_ eq $item} @_;
    }
    @$list_ref = @new_list;
}

# keep or remove items from a list(ref)
# Takes a listref, a (optional) subref, and an item
# returns the elements (array[ref]) of @$l where $sub->($_,$r) returns true(keep) or false(remove)
sub keep {
    my ($l, $r, $sub)=@_;
    unless (ref $sub eq 'CODE') {
	$r=$sub;
	$sub=sub {shift eq shift};
    }
    my @R=grep $sub->($_,$r), @$l;
    wantarray? @R:\@R;
}
sub remove {
    my ($l, $r, $sub)=@_;
    $sub=sub {shift eq shift} unless ref $sub eq 'CODE';
    my @R=grep !$sub->($_,$r), @$l;
    wantarray? @R:\@R;
}

# like keep above, but takes a regex instead of a subref
sub all_matching {
    my $re=shift or confess "no regex";
    my $listref=(ref $_[0] eq 'ARRAY' && scalar @_ == 1)? shift : \@_;
    my @matching=grep /$re/, @$listref;
    wantarray? @matching:\@matching;
}


# takes 2 listrefs; returns list or list ref
sub union {
    my ($list1, $list2) = @_;
    my %hash;
    map { $hash{$_}=1 } @$list1;
    map { $hash{$_}=1 } @$list2;
    my @keys = keys %hash;
    wantarray? @keys : \@keys;
}

# takes 2 listrefs; returns list or list ref
sub intersection {
    my ($list1, $list2) = @_;
    my (%hash1, %hash2);

    map { $hash1{$_}=1 } @$list1; # gather list 1:
    map { $hash2{$_}=1 if exists $hash1{$_} } @$list2; # gather intersection(list1, list2)

    my @keys = keys %hash2;
    wantarray? @keys : \@keys;
}

# takes 2 listrefs; returns list or list ref
# returns $list1-$list2
sub subtract {
    my ($list1, $list2) = @_;
    my %hash=();
    map { $hash{$_}=$_ } @$list1; # gather list 1
    map { delete $hash{$_} if $_} @$list2 if @$list2; # remove list 2
    
    my @values = values %hash;
    wantarray? @values : \@values;
}

# return all genes in one list, but not both
# takes 2 listrefs; returns list or list ref
sub xor {
    my ($list1, $list2) = @_;
    my %hash;
    do {push @{$hash{$_}}, $_} foreach @$list1;
    do {push @{$hash{$_}}, $_} foreach @$list2;
    while (my ($k,$v)=each %hash) {
	delete $hash{$k} unless @{$hash{$_}}==1;
    }
    my @values = values %hash;
    wantarray? @values : \@values;
}

# invert a hash (ie, foreach k=>v, return a hash with v=>k)
# if there are duplicate values, they get randomly overwritten
# if there are undefined values, they get abandoned
sub invert {
    my %input=(@_==1 && ref $_[0] eq 'HASH')?%{$_[0]}:@_;
    my %output;
    while (my ($k,$v)=each %input) {
	defined $v and $output{$v}=$k;
    }
    wantarray? %output:\%output;
}

# take two hashrefs; copy k,v from h2 into h1 so long as h1->{k} doesn't exist:
sub soft_copy {
    my ($h1,$h2)=@_;
    while (my ($k,$v)=each %$h2) {
	$h1->{$k}=$v unless exists $h1->{$k};
    }
}


# randomize a list by swapping elements $n times
sub shuffle {
    my ($list,$n)=@_;
    my $l=@$list;
    while ($n--) {
	my $i1=int(rand($l));
	my $i2=int(rand($l));
	my $tmp=$list->[$i1];
	$list->[$i1]=$list->[$i2];
	$list->[$i2]=$tmp;
    } 
}

sub is_monotonic_asc {
    my ($list)=@_;
    my $n=@$list or return 0;
    my $e=shift @$list;

    foreach my $f (@$list) {
	do {unshift @$list,$e; return 0} if $e<$f;
    }
    unshift @$list,$e;
    return 1;
}

sub is_monotonic_desc {
    my ($list)=@_;
    my $n=@$list or return 0;
    my $e=shift @$list;

    foreach my $f (@$list) {
	do {unshift @$list,$e; return 0} if $e>$f;
    }
    unshift @$list,$e;
    return 1;
}

# return the min/max/min&max elements of a list, as defined by lt and gt ops
# yes, there are good ways to factor these three routines into the general case.  later.
sub least {
    my $list=(ref $_[0] eq 'ARRAY' && scalar @_ == 1)? shift : \@_;
    confess "not a listref: $list" unless ref $list eq 'ARRAY';
    return undef if @$list==0;
    my $min=$list->[0];
    foreach my $e (@$list) {
	$min=$e if $e < $min;
    }
    $min;
}

sub greatest {
    my $list=(ref $_[0] eq 'ARRAY' && scalar @_ == 1)? shift : \@_;
    confess "not a listref: $list" unless ref $list eq 'ARRAY';
    return undef if @$list==0;
    my $max=$list->[0];
    foreach my $e (@$list) {
	$max=$e if $e > $max;
    }
    $max;
}

sub range {
    my $list=(ref $_[0] eq 'ARRAY' && scalar @_ == 1)? shift : \@_;
    confess "not a listref: $list" unless ref $list eq 'ARRAY';
    return (undef,undef) if @$list==0;
    my ($min,$max)=($list->[0],$list->[0]);
    foreach my $e (@$list) {
	$min=$e if $e < $min;
	$max=$e if $e > $max;
    }
    ($min,$max);
}

sub span {
    my ($list)=@_;
    my ($min,$max)=minmax($list);
    return $max-$min;
}

# return the last element of a list[ref]:
sub end {
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my $last=(scalar @$list)-1;
    $list->[$last];
}

# Get the reverse of a list[ref]:
# really not sure what's wrong with CORE::reverse...
sub reverse {
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my @rev;
    foreach my $e (@$list) {
	unshift @rev,$e;
    }
    wantarray? @rev:\@rev;
}

# split one list into two, around an indicated element.  O(n)
# returns two listrefs, shortest first
sub split_on_elem {
    my $elem=shift;
    confess "missing arg: list[ref]" unless defined $_[0];
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my $i;
    for ($i=0; $list->[$i]!=$elem; $i++) { }
    my @l1=@$list[0..$i];
    my $last=scalar @$list-1;
    my @l2=@$list[$i+1..$last];
    @l1<@l2? (\@l1,\@l2):(\@l2,\@l1);
}


sub array_iterator {
    my ($listref,$subref)=@_;
    foreach my $e (@$listref) { $subref->($e) }
}

sub hash_iterator {
    my ($hashref,$subref)=@_;
    while (my ($k,$v)=each %$hashref) { $subref->($k,$v) }
}

# a slow to run but fast to implement version of list equality.  Suitable for 
# short lists and non-performance critical applications.
# Also, only works for scalars, not objects, unless an 
sub equal_lists {
    my ($l1, $l2, $equals)=@_;
    return undef unless scalar @$l1 == scalar @$l2;
    $equals ||= sub {$_[0] eq $_[1]};

    my @union=union($l1, $l2);
    my @inter=intersection($l1, $l2);
    return undef unless scalar @union == scalar @inter;

    @union=sort @union;
    @inter=sort @inter;

    for (my $i=0; $i<scalar @union; $i++) {
	return undef unless $equals->($union[$i], $inter[$i]);
    }
    return 1;
}

# 
sub in_list {
    my ($list, $elem, $equals)=@_;
    $equals ||= sub {$_[0] eq $_[1]};
    foreach my $e (@$list) {
	return $e if $equals->($e, $elem);
    }
    return undef;
}    

sub first_n {
    my $n=pop @_ or confess "no n";
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my $end=least($n, scalar @$list)-1;
    my @first=@$list[0..$end];
    wantarray? @first:\@first;
}

sub last_n {
    my $n=pop @_ or confess "no n";
    my $list = (ref $_[0] eq 'ARRAY'? $_[0] : \@_);
    my @last=@$list[-$n..-1];
    wantarray? @last:\@last;
}

1;
