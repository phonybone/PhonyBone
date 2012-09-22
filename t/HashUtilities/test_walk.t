#!/usr/bin/env perl 
# -*-perl-*-

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::HashUtilities qw(walk_hash walk_list);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my $hash={this=>'that', these=>'those',
	      some_list=>[qw(pen light rain heavy slow run)],
	      motorcycles=>{honda=>{color=>'red',
				    models=>[qw(nt650 cbr600rr rukus)],
			    },
			    yamaha=>{color=>'blue',
				     models=>[qw(fz1 r1 yz125)],
			    },
			    ktm=>{color=>'orange',
				     models=>[qw(duke 300xc)],
			    },
			    ducati=>{color=>'red',
				     models=>[qw(monster 916 750ss)],
			    },
	      },
	      sample_ids=>[qw(GSM23890 GSM20983 GSM101228 GSM82873)],
    };

    my $subrefs={str=>sub { my ($container, $k,$v)=@_; 
			    $v=urify($v, 'localhost:3000', 'json') if $v=~/^g\w\w[_\d]+$/i; 
			    warn defined $k? "$k -> $v\n" : "$v\n"; },
		 ARRAY=>sub { my ($container, $k,$l)=@_; 
			      my $ls=join(', ', @$l); 
			      warn defined $k? "$k -> $ls\n" : "$ls\n"; },
    };
    walk_hash($hash, $subrefs);
}

sub urify {
    my ($geo_id, $host, $suffix)=@_;
    my $ending=$suffix? ".$suffix" : '';
    join('', 'http://', $host, '/geo/', $geo_id, $ending);
}

main(@ARGV);

