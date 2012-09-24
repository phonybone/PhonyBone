package TestCase;
require v5.6.0;			# for attributes
use Attribute::Handlers;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Test::More;

has 'class' => (is=>'ro', isa=>'Str', required=>1);
class_has 'testcases' => (is=>'rw', isa=>'ArrayRef[CodeRef]', default=>sub{[]});

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

sub setup {
    my $self=shift;
    require_ok($self->class);
    my $real_db_name=$self->class->db_name or confess sprintf "no db_name for class '%s'", $self->class;
    $self->class->db_name('test_'.$real_db_name);
    $self->class->delete_all();
}

__PACKAGE__->meta->make_immutable;


1;
