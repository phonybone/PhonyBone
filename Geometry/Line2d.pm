#!/usr/bin/perl
use strict;
use warnings;
package PhonyBone::Geometry::Line2d;
use base qw(Root);
use Carp;
use Data::Dumper;

#
# Data:
# $self->{p0}: "origin" point
# $self->{p1}: vector away from $self->{p0}
#


# alternative constructor:
sub new {
    my $self=shift;
    my @args=@_;
    if (@args==4) {
	if ($args[0] eq 'p0' && ref $args[1] eq 'Point2d' && $args[2] eq 'p1' && ref $args[3] eq 'Point2d') {
	    return $self->SUPER::new(@args);
	} else {
	    return $self->SUPER::new(p0=>Point2d->new(x=>$_[0],y=>$_[1]),p1=>Point2d->new(x=>$_[2],y=>$_[3]));
	}
    } elsif (@args==2) {
	if (ref $_[0] eq 'Point2d' && ref $_[1] eq 'Point2d') {
	    return $self->SUPER::new(p0=>$_[0],p1=>$_[1]);
	} elsif (ref $_[0] eq 'ARRAY' && ref $_[1] eq 'ARRAY') {
	    return $self->SUPER::new(p0=>Point2d->new(x=>$_[0]->[0],y=>$_[0]->[1]),
				     p1=>Point2d->new(x=>$_[1]->[0],y=>$_[1]->[1]));
	}
    } else {
	confess "unknown format in args for constuctor: ",Dumper(\@args);
    }
    $self->normalize;
}

sub normalize {
    my $self=shift;
    $self->{p1}->normalize;
}

# create a line through two points:
sub join {
    my $self = shift;
    my ($p0,$p1) = @_;
    confess "missing pt(s)" unless $p1;
    return $self->new(p0=>$p0, p1=>$p1->minus($p0));
}

# this is the same as new():
sub vector {
    my $self = shift;
    my ($p0,$p1) = @_;
    confess "missing pt(s)" unless $p1;
    return $self->new(p0=>$p0, p1=>$p1);
}

sub slope {
    my $self=shift;
    my $p1=$self->{p1} or confess "no p1";
    return undef unless $p1->{x};
    return $p1->{y}/$p1->{x};
}

sub y_intercept {
    my $self = shift;
    return undef if $self->{p1}->{x}==0;
    return $self->{p0}->{y} if $self->{p1}->{x}==0;
    my $t = -$self->{p0}->{x}/$self->{p1}->{x};
    return $self->at($t)->{y};
}

sub x_intercept {
    my $self = shift;
    return undef if $self->{p1}->{y} == 0;
    return $self->{p0}->{x} if $self->{p1}->{y} == 0;
    my $t = -$self->{p0}->{y}/$self->{p1}->{y};
    return $self->at($t)->{x};
}

# return the point at which two lines intersect:
sub intersection {
    my $l1 = shift;
    my $l2 = shift or confess "no l2";

    my $a = $l2->{p0}->{y} - $l1->{p0}->{y};
    my $b = $l2->{p1}->{y};
    my $c = $l1->{p1}->{y};

    my $d = $l2->{p0}->{x} - $l1->{p0}->{x};
    my $e = $l2->{p1}->{x};
    my $f = $l1->{p1}->{x};

    return undef if $b*$f == $c*$e; # lines are parellel

    my $t = ($c*$d - $a*$f)/($b*$f - $c*$e);
    my $x = $l2->{p0}->{x} + $l2->{p1}->{x}*$t;
    my $y = $l2->{p0}->{y} + $l2->{p1}->{y}*$t;

    return Point2d->new(x => $x, y => $y);
}

# return a two-element list(ref) containing the two values of t
# representing the point of intersection between $l1 and $l2:
sub intersection2t {
    my $l1 = shift or confess "no l1 (aka 'self')";
    my $l2 = shift or confess "no l2";

    my $a = $l2->{p0}->{y} - $l1->{p0}->{y};
    my $b = $l2->{p1}->{y};
    my $c = $l1->{p1}->{y};

    my $d = $l2->{p0}->{x} - $l1->{p0}->{x};
    my $e = $l2->{p1}->{x};
    my $f = $l1->{p1}->{x};

    return undef if $b*$f == $c*$e; # lines are parellel

    my $t2 = ($c*$d - $a*$f)/($b*$f - $c*$e);
    my $t1 = $c? ($a + $b*$t2)/$c : 
	$f? ($d + $e*$t2)/$f 
	    : confess "c and f are both 0???";

    return wantarray? ($t1, $t2) : [$t1, $t2];
}

# return a line perpendicular to $self, intersecting $self at $self->{p0}
sub perpendicular {
    my $self = shift;

    my $pp1 = Point2d->new(x => -$self->{p1}->{y},
			   y =>  $self->{p1}->{x});
    return Line2d->new(p0=>$self->{p0}, p1=>$pp1);
}


# return a line that is the perpendicular bisector of two points:
# return undef if $p1 == $p2
sub bisector {
    my $self = shift;
    my %argHash = @_;
    my $p1 = $argHash{p1} or confess "no p1";
    my $p2 = $argHash{p2} or confess "no p2";
    return undef if $p1->equals($p2);

    my $p0 = $p1->midpoint($p2);
    return Line2d->new(p0=>$p0, p1=>$p0->minus($p1))->perpendicular;
}

# return the point on the line at t=$t:
sub at {
    my $self = shift;
    my $t = shift;
    confess "no t" unless defined $t;

    my $x = $self->{p0}->{x} + $self->{p1}->{x}*$t;
    my $y = $self->{p0}->{y} + $self->{p1}->{y}*$t;
    return Point2d->new(x=>$x, y=>$y);
}

# return the point (t-value) on a list closest to a given point $pt
# method: create a line through $pt and perpendicular to $self.
# then find the intersection of this new line and $self
sub closest_t {
    my $self = shift;
    my $pt = shift or confess "no point";

    # first create a parellel line:
    my $par = Line2d->new(p0 => $pt, p1 => $self->{p1});
    my $perp = $par->perpendicular;
    my ($t1, $t2) = $self->intersection2t($perp);
    return $t1;
}

# return 1 if $self->{t0}<=$t<=$self->{t1}, 0 otherwise
sub contains {
    my ($self,$t)=@_;
    return 0 if defined $self->{t0} && $self->{t0}>$t;
    return 0 if defined $self->{t1} && $self->{t1}<$t;
    return 1;
}

sub clip {
    my ($self,$subscript,$t)=@_;
#    warn (($self->{key}||'some line'),"->clip($subscript,$t) called\n");
    my $old_t=$self->{$subscript};
    if (!defined $old_t) {
	$self->{$subscript}=$t;
    } else {
	$self->{t0}=$t if ($subscript eq 't0' && $old_t<$t);
	$self->{t1}=$t if ($subscript eq 't1' && $old_t>$t);
    }
#    warn $self->as_string_segment,"\n";
}

sub clear_ts {
    my $self=shift;
    delete $self->{t0};
    delete $self->{t1};
    $self;
}

# return 1 if $self as ever been clipped (either side), 0 otherwise
sub clipped {
    my $self=shift;
    return (defined $self->{t0} || defined $self->{t1})? 1:0;
}

sub as_string_segment {
    my $self = shift;

    # calc name, origin & vector, t0 & t1:
    my $key = $self->{key} || 'unnamed string';
    my $q0 = $self->{p0}->as_string;
    my $q1 = $self->{p1}->as_string;
    my $t0 = $self->{t0};
    my $t1 = $self->{t1};

    # segment is invalid if t0>t1:
    my $invalid = ((defined $t0) && (defined $t1) && ($t0 > $t1)) ? '(INVALID)':'';

    # calc endpoints:
    my $p0 = defined $t0? $self->at($t0)->as_string : '-inf';
    my $p1 = defined $t1? $self->at($t1)->as_string : 'inf';

    $t0 = defined $t0? sprintf "%5.2g", $t0 : 'undef';
    $t1 = defined $t1? sprintf "%5.2g", $t1 : 'undef';
    
    my $str = sprintf "$key p=$q0 m=$q1: %14s->%14s (t: $t0->$t1) $invalid", $p0, $p1
}

sub invalid {
    my $self = shift;
    my $t0 = $self->{t0} or return undef;
    my $t1 = $self->{t1} or return undef;
    return $t0>$t1;
}

sub invalidate {
    my $self=shift;
    $self->{t0}=1;
    $self->{t1}=-1;
    $self;
}

# return a coderef that allows evaluation of the line for a given t:
# function called like "$f=$l->as_function_t();$p=&$f($t)"
sub as_function_t {
    my $self=shift;

    sub { 
	my $t=shift;
	confess "no t" unless defined $t;

	my $x = $self->{p0}->{x} + $self->{p1}->{x}*$t;
	my $y = $self->{p0}->{y} + $self->{p1}->{y}*$t;
	return Point2d->new(x=>$x, y=>$y);
    }    
}

# return a coderef that allows evaluation of the line for a given x:
# function returns f(x)=y
sub as_function_xy {
    my $self=shift;
    my $m=$self->slope;
    my $b=$self->y_intercept;

    sub {
	my $x=shift; confess "no x" unless defined $x;
	return undef unless defined $m;
	return $m*$x+$b;
    }

}

# write out the segment in svg
# what to do if segment is unbounded? Extend a bit
sub svg {
    my $self=shift;
    my %argHash=@_;
    my $prec=$argHash{prec} || "%6.4g";    delete $argHash{prec};
    my $prefix=$argHash{prefix} || '';    delete $argHash{prefix};
    $prefix.=':' if $prefix && $prefix!~/:$/;
    return '' if $self->invalid;  # don't draw invisible lines

    my $p1=$self->at(defined $self->{t0}?$self->{t0}:-(Root::VERY_LARGE));
    my $p2=$self->at(defined $self->{t1}?$self->{t1}:+(Root::VERY_LARGE));
    my $svg=sprintf "<${prefix}line x1='$prec' y1='$prec' x2='$prec' y2='$prec'",$p1->{x},$p1->{y},$p2->{x},$p2->{y};

    $argHash{id}=$self->{key} if $self->{key};
    $argHash{stroke}='black' unless $argHash{stroke};
    $argHash{'stroke-width'}=1 unless $argHash{'stroke-width'};

    while (my($attr,$value)=each %argHash) {
	$svg.=" $attr='$value'";
    }
    $svg.='/>';
}

sub as_js {
    my $self=shift;
    my $p0=$self->at($self->{t0});
    my $p1=$self->at($self->{t1});
    my $js=sprintf "ln%s: {x1:%g, y1:%g, x2:%g, y2:%g}",$self->{key},$p0->{x},$p0->{y},$p1->{x},$p1->{y};
}

1;
