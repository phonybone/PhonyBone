package P1a;
use strict;
use warnings;
use Carp;
use Data::Dumper;

########################################################################
##
## Name:      
## Author:    
## Created:   
## $Id: P1a.pm,v 1.1 2008/08/26 03:05:43 vcassen Exp $
##
## Description:
##
########################################################################


use base qw(PhonyBone::Persistable);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw(pa_id p1a_a p1a_b);
@CLASS_ATTRIBUTES=qw(dbh tablename primary_key db_name);
%DEFAULTS = (
	     tablename=>'p1a',
	     primary_key=>'pa_id',
	     indexes=>{},
	     db_name=>'vcassen',
	     );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
    $self->p1a_a('p1a_a');
    $self->p1a_b('p1a_b');
}
    
sub _init_class {
    my ($class)=@_;
    $class->connect_dbh;
}

__PACKAGE__->_init_class;


1;
