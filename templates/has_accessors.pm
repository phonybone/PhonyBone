package PackageName;
use HasAccessors qw(:all);
use base qw(HasAccessors);
add_accessors(qw());
require_attrs(qw());

sub new {
    my ($proto,%args)=@_;
    my $class = ref $proto || $proto;
    my $self=$class->SUPER::new(%args);

    # object initialization goes here as needed

    $self;
}


1;
