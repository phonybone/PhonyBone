#!/usr/bin/env perl
use strict;
use warnings;

package PhonyBone::StringUtilities;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(full_split);

use Data::Dumper;

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


1;
