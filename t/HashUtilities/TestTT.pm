package TestTT;
use namespace::autoclean;

use Moose;
extends 'TestCase';
with 'HashFixture';
use parent qw(TestCase);
use Test::More;
use Data::Dumper;
use Template::Stash;

before qr/^test_/ => sub { shift->setup };


sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}


sub test_template {
    my ($self)=@_;

    my %config=();
    my $t=Template->new(%config);

    # attempt to define a Template routine called 'ref' that mimics perl 'ref':
    if (1) {
	Template::Stash->define_vmethod('scalar', 'ref', sub { 'SCALAR' });
	Template::Stash->define_vmethod('array', 'ref', sub { 'ARRAY' });
	Template::Stash->define_vmethod('hash', 'ref', sub { 'HASH' });
    } else {
	$Template::Stash::SCALAR_OPS->{ref} = sub { 'SCALAR' };
	$Template::Stash::LIST_OPS->{ref} = sub { 'ARRAY' };
	$Template::Stash::HASH_OPS->{ref} = sub { 'HASH' };
    }
    
    my $input='hash.tt';
#    my $hash=$self->hash;
    my $hash={
	this=>'that',
	these=>'those',
	list=>[qw(a b), [qw(c d)]],
   };
    my $vars={
#	dump => Dumper($hash),
#	left_tag=>'{',
#	right_tag=>'}',
	hash=>$hash};

    $t->process($input, $vars) or die $t->error;
}

__PACKAGE__->meta->make_immutable;

1;
