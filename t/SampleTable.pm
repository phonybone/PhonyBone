package SampleTable;
use base qw(PhonyBone::Relational);


use base qw(PhonyBone::Relational);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES=@PhonyBone::Relational::RELATIONAL_CLASS_ATTRS;
%DEFAULTS = (dbh_info=>{engine=>'mysql',
			host=>'localhost',
			db_name=>'vcassen',
		    },
	     tablename=>'sample_table',
	     table_fields=>{ sample_table_id=>'INT PRIMARY KEY',
			 },
	     );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}



1;
