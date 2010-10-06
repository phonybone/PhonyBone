#!/usr/bin/perl
use strict;
use warnings;

package PhonyBone::Geometry::Point2d;
use base qw(PhonyBone::Geometry::Root);
use Carp;
use Data::Dumper;

# class variables:

sub new {
    my $self=shift;
    my @args=@_;
    if (@args==2) {
	return $self->SUPER::new(x=>$_[0],y=>$_[1]);
    } elsif (@args==4) {
	return $self->SUPER::new(@args);
    } else {
	confess "bad args: ",Dumper(\@args);
    }
}

sub midpoint {
    my $p1 = shift;
    my $p2 = shift or confess "no p2";

    my $x = ($p1->{x} + $p2->{x})/2.0;
    my $y = ($p1->{y} + $p2->{y})/2.0;
    return Point2d->new(x=>$x, y=>$y);
}

sub equals {
    my $self = shift;
    my $p2 = shift or confess "no p2";

    my $d = $self->{x} - $p2->{x};
    $d = -$d if $d<0;
    return 0 if ($d>PhonyBone::Geometry::Root::VERY_SMALL);

    $d = $self->{y} - $p2->{y};
    $d = -$d if $d<0;
    return $d<=PhonyBone::Geometry::Root::VERY_SMALL;
}

sub plus {
    my $self = shift;
    my $p2 = shift or confess "no p2";
    return Point2d->new(x=>$self->{x}+$p2->{x}, y=>$self->{y}+$p2->{y});
}

sub minus {
    my $self = shift;
    my $p2 = shift or confess "no p2";
    return Point2d->new(x=>$self->{x}-$p2->{x}, y=>$self->{y}-$p2->{y});
}

# determine if $self is inside the polygon described by a list of points
# there are lots of weird cases, like if polygon crosses over itself, 
# that are untested.  Buyer beware.
sub inside {
    my $self = shift;
    confess "no pts" unless $_[0];
    my $pts = ref $_[0] eq 'ARRAY'? $_[0] : \@_;
    confess "not enough points" unless @$pts >= 3;

    # translate self and polygon to the origin:
    my @pts = map { $_->minus($self) } @$pts;

    # for each pair of points, if the line between them crosses the positive x-axis,
    # count it:
    my $count = 0;
    my $last_pt = $pts[$#pts];
    foreach my $pt (@pts) {

	unless ((($pt->{y}>0) && ($last_pt->{y}>0)) || (($pt->{y}<=0) && ($last_pt->{y}<=0))) {
	    my $l = Line2d->join($last_pt, $pt);
	    my $x_int = $l->x_intercept;
	    $count++ if (defined $x_int && ($x_int)>0);	# shouldn't $x_int always be defined if 
	    # signs of y-coords change? oh well
	}

	$last_pt = $pt;
    }
    return $count & 1;
}

    
# return 1 if ($p1,$p2,$p3) describes a clockwise path
#        0 if ccw or linear
sub clockwise {
    my ($p1,$p2,$p3)=@_;
    # one method: translate all points so $p1 at origin,
    # rotate $p2 & $p3 s.t $p2 is on origin, 
    # then return $p3->y > 0
    # OR
    # find line defined by $p1,$p2 in terms of ax+by+c=0
    # plug coordinates of $p3 into equation
    # if answer is +, then cw
    # if answer is -, then ccw

    # Let's go with solution #2 for the moment: (rotation is a pain)
    # Don't forget pathological cases: two or more points the same, or all points linear
    my ($slope,$b)=slope_intercept($p1,$p2);
    if (!defined $slope) {	# vertical
	return 0 if $p3->{x}==$p1->{x};	# colinear
	return $p1->{y}>$p2->{y}? $p3->{x}<$p1->{x} : $p3->{x}>$p1->{x};
    }
    if ($slope==0) {		# horizontal
	my $answer;
	$answer=0 if $p3->{y}==$p1->{y};	# colinear
	defined $answer or $answer=$p1->{x}>$p2->{x}? $p3->{y}>$p1->{y} : $p3->{y}<$p1->{y};
#	warn "clockwise: horizontal line, p1x=",$p1->{x},", p2x=",$p2->{x},", p3x=",$p3->{x},", returning ",($answer||'null'),"\n";
	return $answer;
    }
    
    # function for line through (p1,p2) is now $y=$slope*$x+$b
    # plug in $p3->{x} and compare to $p3->{y}:
    my $y=($slope*$p3->{x}+$b);
#    warn "clockwise: m=$slope, b=$b, y=$y\n";
    return $y<$p3->{y} if $p1->{x}>$p2->{x};
    return $y>$p3->{y};
}


# return the slope and y intercept of a line going through two points
# for vertical lines, returns (undef,undef)
sub slope_intercept {
    my ($p1,$p2)=@_;
    my $dem=$p2->{x}-$p1->{x};
    return (undef,undef) if $dem==0;
    my $m=($p2->{y}-$p1->{y})/$dem;
    my $b=$p1->{y}-$m*$p1->{x};
    ($m,$b);
}

# return the distance between two points:
sub distance_to {
    my ($self,$p)=@_;
    if (!ref $self && @_>2 && ref $_[2] eq __PACKAGE__) {
	$self=$_[2];
    }
    confess "bad point: ",Dumper($p) unless defined $p->{x} && defined $p->{y};
    my $dx=$self->{x}-$p->{x};
    my $dy=$self->{y}-$p->{y};
    sqrt(($dx*$dx)+($dy*$dy));
}

sub magnitude {
    my $self=shift;
    return $self->distance_to($self->new(x=>0,y=>0));
}

sub normalize {
    my $self=shift;
    my $scale=shift || 1;
    my $m=$self->magnitude;
    confess "Can't normalize a point with magnitude=0" if $m==0;
    $self->{x}/=($m*$scale);
    $self->{y}/=($m*$scale);
    $self;
}

sub as_string {
    my $self = shift;
    my $x = $self->{x};
    my $y = $self->{y};
    return sprintf "(% 04.2f,% 04.2f)", $x, $y;
}

sub svg {
    my $self=shift;
    my %argHash=@_;
    my $prec=$argHash{prec} || "%6.4g";
    my $rad=$argHash{radius} || 1;
    delete $argHash{prec};
    delete $argHash{radius};

    my $prefix=$argHash{prefix} || '';    delete $argHash{prefix};
    $prefix.=':' if $prefix && $prefix!~/:$/;

    my $svg=sprintf "<${prefix}circle cx='$prec' cy='$prec' r='$rad'",$self->{x},$self->{y};
    while (my($attr,$value)=each %argHash) {
	$svg.=" $attr='$value'";
    }
    $svg.='/>';
}

sub as_js {
    my $self=shift;
    sprintf"{x:%g, y:%g}",$self->{x},$self->{y};
}

1;

