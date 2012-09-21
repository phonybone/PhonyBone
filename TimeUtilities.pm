package PhonyBone::TimeUtilities;
use warnings;
use strict;
use Readonly;

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK=qw(tlm n_days0 n_days1 duration);

# three-letter months
our @tlms=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
sub tlm { $tlms[shift] }

our @n_days=(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
sub n_days1 { $n_days[shift(@_)+1] }
sub n_days0 { $n_days[shift] }

Readonly my $SECS_IN_MIN => 60;
Readonly my $SECS_IN_HOUR => 60 * $SECS_IN_MIN;
Readonly my $SECS_IN_DAY => 24 * $SECS_IN_HOUR;
Readonly my $SECS_IN_YEAR => 365 * $SECS_IN_DAY;

sub duration {
    my $n_secs=shift;
    
    my $n_years=int($n_secs/$SECS_IN_YEAR);
    $n_secs %= $SECS_IN_YEAR;

    my $n_days=int($n_secs/$SECS_IN_DAY);
    $n_secs %= $SECS_IN_DAY;

    my $n_hours=int($n_secs/$SECS_IN_HOUR);
    $n_secs %= $SECS_IN_HOUR;

    my $n_mins=int($n_secs/$SECS_IN_MIN);
    $n_secs %= $SECS_IN_MIN;

    my (@line, $s);
    foreach my $pair (grep {$_->[0]} ([$n_years, 'year'], [$n_days, 'day'], [$n_hours, 'hour'], [$n_mins, 'min'], [$n_secs, 'sec'])) {
	my ($n, $label)=@$pair;
	$s = $n==1? '':'s';
	push @line, sprintf("%d %s%s", $n, $label, $s);
    }
    join(', ', @line);
}

1;


