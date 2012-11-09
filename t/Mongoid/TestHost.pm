package TestHost;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Person;

before qr/^test_/ => sub { shift->setup };


sub test_host : Testcase {
    my ($self)=@_;
    Person->host('some_host');
    cmp_ok(Person->host, 'eq', 'some_host');
}

__PACKAGE__->meta->make_immutable;

1;
