package Fred;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;

has 'x' => (is=>'ro', isa=>'Int');
class_has 'class_attr' => (is=>'ro', isa=>'Str');

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( primary_key => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};

sub BUILD { 
    my $self=shift;
    $self;
}


__PACKAGE__->meta->make_immutable;

1;
