package TestCase;
require v5.6.0;			# for attributes
use Attribute::Handlers;
use namespace::autoclean;
use Moose;
use Test::More;

has 'class' => (is=>'ro', isa=>'Str', required=>1);

# Attribute handler
sub testcase : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data) = @_;
    foreach my $thing (qw(package symbol referent attr data)) {
	eval "warn \"$thing is \$$thing\"";
    }
    warn "\n";
}


sub setup {
    my $self=shift;
    require_ok($self->class);
    my $real_db_name=$self->class->db_name;
    $self->class->db_name('test_'.$real_db_name);
    $self->class->delete_all();
}

before qr/^test_/ => sub { shift->setup };

__PACKAGE__->meta->make_immutable;


1;
