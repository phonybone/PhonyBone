package Motorcycle;
use Moose;
#use namespace::autoclean;	# can't use this with overloads

has 'make'  => (is=>'ro', isa=>'Str', required=>1);
has 'model' => (is=>'ro', isa=>'Str', required=>1);
has 'year'  => (is=>'ro', isa=>'Int', required=>1);
has 'ccs'   => (is=>'ro', isa=>'Int', required=>1);

use MooseX::ClassAttribute;
class_has 'db_name' => (is=>'rw', isa=>'Str', default=>'motorcycles'); 
class_has 'collection_name' => (is=>'rw', isa=>'Str', default=>'motorcycles'); 
with 'Mongoid';

sub as_str {
    my ($self)=@_;
    sprintf "%d %s %s %dcc", $self->year, $self->make, $self->model, $self->ccs;
}
use overload '""' => \&as_str;



__PACKAGE__->meta->make_immutable;

1;
