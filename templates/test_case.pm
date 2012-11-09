package ;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);

before qr/^test_/ => sub { shift->setup };


sub test_something : Testcase {
    my ($self)=@_;
}

__PACKAGE__->meta->make_immutable;

1;
