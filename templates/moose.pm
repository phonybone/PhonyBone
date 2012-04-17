package Fred;
use Carp;
use Data::Dumper;

use Moose;
use MooseX::ClassAttribute;

has x=>(is=>'rw', isa=>'Int');
class_has class_attr=>(is=>'rw', isa=>'Str');

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

1;
