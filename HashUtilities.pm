#!/usr/bin/env perl
use strict;
use warnings;

package PhonyBone::HashUtilities;
use base qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(walk_hash walk_list hgrep);

use Carp qw(confess);
use Data::Dumper;

# walk_hash and walk_list recurse through a hash, calling a subref
# for each element in the hash according to the type of the value
# of each k-v pair:
sub walk_hash {
    my ($hash, $subrefs)=@_;
    
    while (my ($k,$v)=each %$hash) {
	my $type=ref $v;
	if ($type eq 'HASH') {
	    if (my $hsub=$subrefs->{HASH}) { $hsub->($hash, $k,$v); }
	    walk_hash($v, $subrefs);
	} elsif ($type eq 'ARRAY') {
	    if (my $asub=$subrefs->{ARRAY}) { $asub->($hash, $k,$v); }
	    walk_list($v, $subrefs);
	} elsif ($type eq 'SCALAR') {
	    if (my $srsub=$subrefs->{SCALAR}) { $srsub->($hash, $k,$v); }
	} else {		# regular scalar
	    if (my $ssub=$subrefs->{str}) { $ssub->($hash, $k,$v); }
	}
    }
    $hash;
}

sub walk_list {
    my ($list, $subrefs)=@_;
    confess("not a array: '$list'") unless ref $list eq 'ARRAY';
    my $i=0;
    foreach my $e (@$list) {
	my $type=ref $e;
	if ($type eq 'HASH') {
	    if (my $hsub=$subrefs->{HASH}) { $hsub->($list, $i, $e); }
	    walk_hash($e, $subrefs);
	} elsif ($type eq 'ARRAY') {
	    if (my $asub=$subrefs->{ARRAY}) { $asub->($list, $i, $e); }
	    walk_list($e, $subrefs);
	} elsif ($type eq 'SCALAR') {
	    if (my $srsub=$subrefs->{SCALAR}) { $srsub->($list, $i, $e); }
	} else {		# regular scalar
	    if (my $ssub=$subrefs->{str}) { $ssub->($list, $i, $e); }
	}
	$i+=1;
    }
    $list;
}

# grep through the key-value pairs of a hash[ref], using a subref or regex.
# call as hgrep(%hash, $sub_or_regex) or hgrep($hashref, $sub_or_regex).
# if a regex is passed, looks at the VALUES of the hash[ref]
# returns a hash[ref]
sub hgrep {
    my $subref=pop @_;
    confess "$subref: not a CODE reference or regex" 
	unless ref $subref eq 'CODE' or ref $subref eq 'Regexp';
    my %hash=scalar @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;

    my %result=();
    while (my ($k,$v)=each %hash) {
	if (ref $subref eq 'CODE') {
	    $result{$k}=$v if $subref->($k,$v);
	} else {
	    $result{$k}=$v if $v=~/$subref/; # $subref really a Regexp in this case
	}
    }
    
    wantarray? %result:\%result;
}


1;
