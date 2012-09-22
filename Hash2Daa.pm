package PhonyBone::Hash2Daa;
require 5.10.0;

use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::Hash2D';

has 'data' => (is=>'ro', isa=>'ArrayRef', default=>sub{[]});

has '_x2i' => (is=>'ro', isa=>'HashRef', default=>sub{{}});
sub _col { $_[0]->_x2i->{$_[1]} }

has '_y2i' => (is=>'ro', isa=>'HashRef', default=>sub{{}});
sub _row { $_[0]->_y2i->{$_[1]} }

has 'x_next' => (is=>'rw', isa=>'Int', default=>0);
has 'y_next' => (is=>'rw', isa=>'Int', default=>0);

has 'col0_header' => (is=>'rw', isa=>'Str', default=>'');

sub put {
    my ($self, $x, $y, $value)=@_;
    my $row=$self->_row($y) // $self->_new_row($y);
    my $col=$self->_col($x) // $self->_new_col($x);
    $self->data->[$row]->[$col]=$value;
    $value;
}

sub get {
    my ($self, $x, $y)=@_;
    my $row=$self->_row($y);
    return undef unless defined $row;
    my $col=$self->_col($x);
    return undef unless defined $col;
    $self->data->[$row]->[$col];
}

sub x_axis {
    my ($self)=@_;
    my $x2i=$self->_x2i;
    my @xs=map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, $x2i->{$_}]} keys %$x2i; # schwartzian transformation
    \@xs;
#    wantarray? @xs:\@xs;
}

sub y_axis {
    my ($self)=@_;
    my $y2i=$self->_y2i;
    my @ys=map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, $y2i->{$_}]} keys %$y2i; # schwartzian transformation
    \@ys;
#    wantarray? @ys:\@ys;
}

########################################################################

sub _new_row {
    my ($self, $row_name)=@_;
    my $y_next=$self->y_next;
    $self->_y2i->{$row_name}=$y_next;
    $self->data->[$y_next]=[];
    $self->y_next($y_next+1);
    $y_next;
}

sub _new_col {
    my ($self, $col_name)=@_;
    my $x_next=$self->x_next;
    $self->_x2i->{$col_name}=$x_next;
#    $self->data->[$x_next]=[];
    $self->x_next($x_next+1);
    $x_next;
}



__PACKAGE__->meta->make_immutable;

1;
