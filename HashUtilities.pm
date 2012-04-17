#!/usr/bin/env perl
use strict;
use warnings;

package PhonyBone::HashUtilities;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(walk_hash walk_list);

use Carp qw(confess);

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

1;
