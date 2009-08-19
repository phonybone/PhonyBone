package PhonyBone::TaggableA::Image;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use PhonyBone::ListUtilities qw(soft_copy);

use base qw(PhonyBone::TaggableA::File);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS %SYNONYMS @ISA);
@AUTO_ATTRIBUTES = qw(alt height width);
@CLASS_ATTRIBUTES = qw(tablename table_fields type);
%DEFAULTS = (tablename=>'taggable_image',
	     table_fields=>{
		 alt=>'VARCHAR(255)',
		 height=>'INT',
		 width=>'INT',
	     },
	     type=>'Image',
);
%SYNONYMS = ();

Class::AutoClass::declare(__PACKAGE__);


sub _init_self {
    my ($self, $class, $args) = @_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

sub _init_class {
    my $class=shift;
    my $fields=$class->table_fields;
    foreach my $pclass (@ISA) {
	my $pfields=$pclass->table_fields or next;
	soft_copy($fields,$pfields);
    }
    $class->table_fields($fields);
    $class->SUPER::_init_class;
}

__PACKAGE__->_init_class;

1;
