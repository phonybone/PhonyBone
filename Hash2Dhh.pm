package PhonyBone::Hash2Dhh;
use Moose;
extends 'PhonyBone::Hash2D';

# Convert a "2D" hash to a .csv file
# A "2D" hash is a table where both x- and y-axis's
# are labeled with associative value.  As such, there
# is no inherent ordering to either axis, but this implementation
# uses the order in which the keys were created (using put()).
#
# Interpret keys %{$self->_data} as horizontal headers

use Carp;
use Data::Dumper;
use namespace::autoclean;


has '_data' => (is=>'ro', isa=>'HashRef', default=>sub{{}});
has 'col0_header' => (is=>'rw', isa=>'Str', default=>'');

has '_x_axis_h' => (is=>'rw', isa=>'HashRef', default => sub{{}}); # k=name, v=rank
has '_x_axis' => (is=>'rw', isa=>'ArrayRef', default => sub{[]});
has '_is_x_axis_dirty' => (is=>'rw', isa=>'Int', default=>0);
has 'x_next' => (is=>'rw', isa=>'Int', default=>0);

has '_y_axis_h' => (is=>'rw', isa=>'HashRef', default => sub{{}}); # as above
has '_y_axis' => (is=>'rw', isa=>'ArrayRef', default => sub{[]});
has '_is_y_axis_dirty' => (is=>'rw', isa=>'Int', default=>0);
has 'y_next' => (is=>'rw', isa=>'Int', default=>0);


sub _add_x {
    my ($self, $x)=@_;
    unless (defined $self->_x_axis_h->{$x}) {
	my $x_next=$self->x_next;
	$self->_x_axis_h->{$x}=$x_next;
	$self->x_next(++$x_next);
	$self->_is_x_axis_dirty(1);
    }
    $self;
}

sub x_axis {
    my ($self)=@_;
    return $self->_x_axis unless $self->_is_x_axis_dirty;
    my @x_axis=map {$_->[0]} 
        sort {$a->[1] <=> $b->[1]} 
           map {[$_, $self->_x_axis_h->{$_}]} 
              keys %{$self->_x_axis_h};
    $self->_x_axis(\@x_axis);
    $self->_is_x_axis_dirty(0);
    \@x_axis;
}

sub y_axis {
    my ($self)=@_;
    return $self->_y_axis unless $self->_is_y_axis_dirty;
    my @y_axis=map {$_->[0]} 
        sort {$a->[1] <=> $b->[1]} 
           map {[$_, $self->_y_axis_h->{$_}]} 
              keys %{$self->_y_axis_h};
    $self->_y_axis(\@y_axis);
    $self->_is_y_axis_dirty(0);
    \@y_axis;
}

sub _add_y {
    my ($self, $x)=@_;
    unless (defined $self->_y_axis_h->{$x}) {
	my $y_next=$self->y_next;
	$self->_y_axis_h->{$x}=$y_next;
	$self->y_next(++$y_next);
	$self->_is_y_axis_dirty(1);
    }
    $self;
}


sub put {
    my ($self, $x, $y, $value)=@_;
    $self->_add_x($x)->_add_y($y);
    $self->_data->{$x}->{$y}=$value;
}

sub get {
    my ($self, $x, $y)=@_;
    $self->_data->{$x}->{$y};
}

__PACKAGE__->meta->make_immutable;

1;
