package TestWalk;
use namespace::autoclean;

use Moose;
extends 'TestCase';
with 'HashFixture';
use parent qw(TestCase);
use Test::More;
use PhonyBone::HashUtilities qw(walk_hash walk_list);

before qr/^test_/ => sub { shift->setup };


sub print_hash {
    my ($self)=@_;
    my $hash=$self->hash;

    # set of callbacks:
    # str: call urify on the values that match GEO ids, then print out value
    my $subrefs={str=>sub { my ($container, $k,$v)=@_; 
			    $v=urify($v, 'localhost:3000', 'json') if $v=~/^g\w\w[_\d]+$/i; 
			    my ($lb,$rb)=ref $container eq 'ARRAY'? qw([ ]) : qw({ });
			    warn defined $k? "$lb$k$rb -> $v\n" : "$v\n"; },
		 # ARRAY: 
		 ARRAY=>sub { my ($container, $k,$l)=@_; 
			      my $ls=join(', ', @$l); 
			      warn defined $k? "$k: $ls\n" : "$ls\n"; },
    };
    walk_hash($hash, $subrefs);
}

sub urify {
    my ($geo_id, $host, $suffix)=@_;
    my $ending=$suffix? ".$suffix" : '';
    join('', 'http://', $host, '/geo/', $geo_id, $ending);
}




__PACKAGE__->meta->make_immutable;

1;
