package PhonyBone::Benchmarks;
use Carp;
use Data::Dumper;
use namespace::autoclean;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

use Moose;
has 'tss' => (is=>'ro', isa=>'ArrayRef', default=>sub{[]});
has 'last_ts' => (is=>'rw', isa=>'Str');

# record a timepoint:
sub tick {
    my $ts=clock_gettime(CLOCK_MONOTONIC);
    my ($self, $msg)=@_;
    push @{$self->tss}, [$ts, $msg];
}

# return a report of timepoints:
sub report {
    my ($self)=@_;
    my $tss=$self->tss;
    my @report;
    my $last_ts;
    foreach my $ts_pair (@$tss) {
	my ($ts, $msg)=@$ts_pair;
	unless (defined $last_ts) { # first iteration
	    push @report, $msg;
	    $last_ts=$ts;
	    next;
	}

	my $dt=$ts-$last_ts;
	$last_ts=$ts;
	push @report, sprintf "%s: %ss\n", $msg, $dt;
    }
    join("\n",@report);
}

# like tick(), but instead return an instaneous mini-report using the last timepoint:
sub mark {
    my $ts=clock_gettime(CLOCK_MONOTONIC);
    my ($self, $msg)=@_;
    my $report;
    if (my $lts=$self->last_ts) {
	my $dt=$ts-$lts;
	$report=sprintf "%s: %s", $dt, $msg;
    } else {
	$report=$msg;
    }
    $self->last_ts($ts);
    push @{$self->tss}, [$ts, $msg]; # in case user wants a full report later
    return $report;
}

__PACKAGE__->meta->make_immutable;

1;
