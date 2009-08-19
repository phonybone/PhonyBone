package PhonyBone::;
use base qw(Class::AutoClass);


use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES=qw();
%DEFAULTS = (
	     );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}



1;
