package PhonyBone::Geometry::Polar;
use HasAccessors qw(:all);
use base qw(HasAccessors);
add_accessors(qw(r theta));
require_attrs(qw());


sub new {
    my ($proto,%args)=@_;
    my $class = ref $proto || $proto;
    my $self=$class->SUPER::new(%args);

    # object initialization goes here as needed

    $self;
}

sub xy {
    my $self=shift;
    my @p=($self->r * cos($self->theta), $self->r * sin($self->theta));
    wantarray? @p:\@p;
}

# return the square of the distance (magnitude)
sub d2 {
    my ($p1,$p2)=@_;
    ($p1->r * $p1->r) + ($p2->r * $p2->r) - 2*$p1->r*$p2->r*cos($p1->theta - $p2->theta);
}
sub d { sqrt(d2(@_)) }


1;
