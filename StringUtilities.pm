#!/usr/bin/env perl
use strict;
use warnings;

package PhonyBone::StringUtilities;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(trim full_split differ_at);

use Data::Dumper;


sub trim {
    my ($s)=@_;
    $s=~s/^\s*//;
    $s=~s/\s*$//;
    $s;
}


=head2
    full_split($str, $regex)

    Split a string via a regex, return a list comprising
    of both the split chunks and the matching regexes
    (unlike ::split).
    returns a list[ref]
=cut

sub full_split {
    my ($str, $regex)=@_;
    my @answer;
#    warn "regex is ",Dumper($regex);

    my $i=0;
    while ($str=~/$regex/gs) {
	my $len=pos($str)-length($&)-$i;
	my $left=substr($str,$i,$len);
	push @answer, $left, $&;
	$i=pos($str);
    }
    # remainder:
    my $remainder=substr($str, $i);
    push @answer, $remainder if $remainder;
    wantarray? @answer:\@answer;
}

# return the index at which two string begin to differ:
sub differ_at {
    my ($s1, $s2)=@_;
    my $l1=length $s1;
    my $l2=length $s2;
    my $l=$l1<$l2? $l1 : $l2;
    my @s1=split('', $s1);
    my @s2=split('', $s2);
    foreach my $i (0..$l-1) {
	return $i if $s1[$i] ne $s2[$i];
    }
    return $l;
}

1;
