package Person;
use Carp;
use Data::Dumper;

# can't use autoclean because it clobbers as_str as an overload for '""'
#use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;

has 'firstname' => (is=>'ro', isa=>'Str', required=>1);
has 'lastname' => (is=>'ro', isa=>'Str', required=>1);
has 'age' => (is=>'rw', isa=>'Int', required=>1);

class_has 'db_name' => (is=>'rw', isa=>'Str', default=>'persons'); 
class_has 'collection_name' => (is=>'rw', isa=>'Str', default=>'persons'); 
# this is stupid; we want to be able to configure these on a case-by-case
class_has indexes => (is=>'rw', isa=>'ArrayRef', default=>sub{
    [
     {keys=>['firstname', 'lastname'], opts=>{unique=>1}},
    ]}
    );
with 'Mongoid';

sub as_str {
    my ($self)=@_;
    sprintf "%s %s (age %d)", $self->firstname, $self->lastname, $self->age;
}

use overload '""' => \&as_str;

__PACKAGE__->meta->make_immutable;

1;
