package PhonyBone::Geometry::Rect;
use HasAccessors qw(:all);
use base qw(HasAccessors);
add_accessors(qw(top left bottom right));
require_attrs(qw(top left bottom right));

sub new {
    my ($proto,%args)=@_;
    my $class = ref $proto || $proto;
    my $self=$class->SUPER::new(%args);

    # object initialization goes here as needed

    $self;
}


1;
