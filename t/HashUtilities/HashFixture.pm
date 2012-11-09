package HashFixture;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose::Role;

# hash for testing purposes:
has 'hash' => (is=>'ro', isa=>'HashRef', default=>sub {
{
    this=>'that', 
    these=>'those',
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
}});


1;
