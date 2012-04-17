package PhonyBone::TimeUtilities;
use warnings;
use strict;

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK=qw(tlm);

our @tlms=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
sub tlm { $tlms[shift] }

1;


