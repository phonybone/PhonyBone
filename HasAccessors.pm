package HasAccessors;
use base qw(Exporter);
@EXPORT_OK=qw(add_accessor add_class_accessor add_accessors add_class_accessors 
	      add_accessors_with_defaults set_default set_defaults require_attr require_attrs);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use Data::Dumper;
use Carp;

my %DEFAULTS;

sub new {
    my ($proto,%args)=@_;
    my $class=ref $proto || $proto;
    my $self;
    if ($class->can('SUPER::new')) {
	$self=$class->SUPER::new(%args); # can this actually be called?  Only superclass is Exporter
	# add in anything from %args not already present???
	warn "called $class->SUPER::new";
    } else {
	$self=bless {}, $class;
	while (my($attr,$val)=each %args) {
	    my $accessor=$self->can($attr) or next;
	    $self->$accessor($val);
	}
    }

    # set defaults:
    while (my ($k,$v)=each %{$DEFAULTS{$class}}) {
	next if defined $self->{$k};
	$self->{$k}=$v;
    }

    # check for required parms:
    my @missing;
    foreach my $attr (@{$REQUIRED{$class}}) {
	push @missing, $attr unless defined $self->$attr;
    }
    confess "$class: missing required attributes: ",join(', ',@missing) if @missing;

    if ($self->can('_init_self')) { $self->_init_self($class, %args) }

    $self;
    # fixme: Need to think seriously about whether extra elements of %args
    # are getting copied erroneously
}

sub add_accessor {
    my $class=@_==3? shift:(caller)[0];
    my ($attr,$default)=@_;

    my $method=<<"SUB";
    package $class;
    sub $attr {
	my (\$self,\$val)=\@_;
	\$self->{$attr}=\$val if \@_==2;
	\$self->{$attr};
    }
SUB
    eval $method;

    $class->set_default($attr,$default) if defined $default;
}

sub add_accessors {
    my (@attrs)=@_;
    my $class=(caller)[0];
    foreach my $attr (@attrs) {
	add_accessor($class, $attr, undef);
    }
}

sub add_accessors_with_defaults {
    my (%attrs)=@_;
    my $class=(caller)[0];
    while (my ($attr,$default)=each %attrs) {
	add_accessor($class, $attr, $default);
    }
}


sub add_class_accessor {
    my $class=@_==3? shift:(caller)[0];
    my ($attr,$default)=@_;	# fixme: $default ignored

    my $method=<<"SUB";
    package $class;
    { our \$$attr;
      sub $attr {
	  my (\$class,\$val)=\@_;
	  \$$attr=\$val if \@_==2;
	  \$$attr;
      }
    }
SUB
    eval $method;

    # handle default values; first define, then set:
    $class->set_default($attr,$default) if defined $default;
    if ($default) {
	my $init=<<"INIT";
	$class->$attr($default);
INIT
	eval $init;
    }
}

sub add_class_accessors {
    my (@attrs)=@_;
    my $class=(caller)[0];
    foreach my $attr (@attrs) {
	add_class_accessor($class,$attr,undef);
    }
}

sub set_default {
    my $class=@_==3? shift:(caller)[0];
    my ($attr,$value)=@_;
    confess "set_default($class): no such accessor '$attr'" unless $class->can($attr);
    $DEFAULTS{$class}->{$attr}=$value;
}

sub set_defaults {
    my $class=@_&1? shift:(caller)[0];
    my %defs=@_;
    while (my ($attr,$def)=each %defs) {
	$class->set_default($attr,$def);
    }
}

sub require_attr {
    my $class=@_==2? shift:(caller)[0];
    my ($attr)=@_;
    confess "require_attr($class): no such accessor '$attr'" unless $class->can($attr);
    push @{$REQUIRED{$class}}, $attr;
}

sub require_attrs {
    my $class=@_==2? shift:(caller)[0];
    foreach (@_) {
	$class->require_attr($_);
    }
}

sub set {
    my ($self, $attr, $value)=@_;
    confess "unknown attr: '$attr'" unless $self->can($attr);
#    my $stm="\$self->$attr($value)";
#    eval $stm;
    $self->$attr($value);
    $value;
}

sub get {
    my ($self, $attr)=@_;
    confess "unknown attr: '$attr'" unless $self->can($attr);
    $self->$attr;
}

# fixme: needs testing
sub get_attrs {
    my ($self,@attrs)=@_;
    @{$self{@attrs}};
}

1;
