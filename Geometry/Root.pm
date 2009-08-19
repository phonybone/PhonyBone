#!/usr/bin/perl
use strict;
use warnings;

package PhonyBone::Geometry::Root;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(clone $VERY_LARGE $VERY_SMALL);

use Carp;
use Data::Dumper;

use constant VERY_SMALL => 1E-8;
use constant VERY_LARGE => 1E8;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args = @_;

    my $self = bless \%args, $class;
    return $self;
}

# make a complete (deep) copy of an object:
sub clone {
    my $self = shift;

    my $type;
    my $is_object;
    eval {
	$type = ref $self;
	$self->isa('Root');
	$is_object = 1;
    };
    confess "$self not a ref" unless $type;

    my $clone;
    if ($type eq 'ARRAY') {
	foreach my $t (@$self) {
	    push @$clone, (ref $t? clone($t) : $t);
	}
    } elsif ($type eq 'HASH' || $is_object) {
	$clone = bless {}, $type unless $type eq 'HASH';
	while (my ($k,$v) = each %$self) {
	    $clone->{$k} = ref $v? clone($v) : $v;
	}
    } else {
	confess "Don't know how to clone '$type'";
    }
    $clone;
}

1;
