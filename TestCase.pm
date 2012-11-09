package PhonyBone::TestCase;
require v5.6.0;			# for attributes
use Attribute::Handlers;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Test::More;

has 'class' => (is=>'ro', isa=>'Str', required=>1);
has 'description' => (is=>'ro', isa=>'Str', default=>'Describe what is being tested');

# This has to be a class method because the attribute handler deals with it.
class_has 'testcases' => (is=>'rw', isa=>'ArrayRef[CodeRef]', default=>sub{[]});

around BUILDARGS=>sub {
    my ($orig, $class, @args)=@_;
    my %args;
    if (@args==1 && ! ref $args[0]) {
	$args{class}=$args[0];
    } else {
	%args=@args;
    }
    $class->$orig(%args);
};

# Attribute handler
sub Testcase : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $line) = @_;

    foreach my $thing (qw(package symbol referent attr data phase filename line)) {
#	eval "warn \"$thing is \$$thing\"";
    }
    push @{$package->testcases}, $referent;
    # Still can't wrap $referent in 'before' via Moose...
}

sub run_all_tests {
    my ($self)=@_;
    foreach my $testcase (@{$self->testcases}) {
	$testcase->($self);
    }
}

sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
}

sub setup {
    my $self=shift;
}

__PACKAGE__->meta->make_immutable;


1;
