#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
$Data::Dumper::Deparse=1;
use Test::More qw(no_plan);

use Root qw(clone);
use Line2d;
use Point2d;

MAIN: {
    # Root::clone
    my $line = Line2d->new(p0=>Point2d->new(x=>rand, y=>rand),
			   p1=>Point2d->new(x=>rand, y=>rand));
    my $line_clone = clone($line);
    is_deeply($line_clone, $line, 'cloned an line');

    eval { my $fred = clone(sub {}); };
    like($@, qr"Don't know how to clone 'CODE'", 'caught CODE exception for clone');

    # midpoint
    my $p0 = Point2d->new(x=>rand(2)-1, y=>rand(2)-1);
    my $p1 = Point2d->new(x=>rand(2)-1, y=>rand(2)-1);
    is_deeply($p1->midpoint($p0), $p0->midpoint($p1), 'random midpoints communative');
    
    # point equals:
    ok (! $p0->equals($p1), 'two random points unequal');
    $p0 = Point2d->new(x=>rand, y=>rand);
    $p1 = clone($p0);
    my $e = $p1->equals($p0);
    ok($p1->equals($p0), 'cloned points equal');
		       
    # at:
    my $l = Line2d->new(p0=>Point2d->new(x=>rand(1), y=>rand(1)),
			p1=>Point2d->new(x=>rand(1), y=>rand(1)));
    is_deeply($l->{p0}, $l->at(0), 'at(0)');
    is_deeply($l->{p0}->plus($l->{p1}), $l->at(1), 'at(1)');

    

    # intersection:
    my $l1 = Line2d->new(p0 => Point2d->new(x => 3, y => 6), 
			 p1 => Point2d->new(x => 2, y => 2), 
		     );
    my $l2 = Line2d->new(p0 => Point2d->new(x => 1, y => -1), 
			 p1 => Point2d->new(x => 0, y => 1), 
		     );
    my $p2 = $l1->intersection($l2) || 'undef';
    is_deeply($p2, Point2d->new(x=>1, y=>4), 'intersection @ 1,4');

    is_deeply(Point2d->new(x=>0,y=>0),
	      Line2d->new(p0=>Point2d->new(x=>3, y=>3), p1=>Point2d->new(x=>-1,y=>-1))->intersection
	      (Line2d->new(p0=>Point2d->new(x=>-1,y=>2), p1=>Point2d->new(x=>2,y=>-4))), 
	      'intersection at origin');

    # intersection2t:
    my ($t1, $t2) = $l1->intersection2t($l2);
    is_deeply($l1->at($t1), $l2->at($t2), 'intersection2t');


    # perpendicular:
    $l1 = Line2d->new(p0=>Point2d->new(x=>1, y=>0), p1=>Point2d->new(x=>0,y=>1))->perpendicular;
    $l2 = Line2d->new(p0=>Point2d->new(x=>1, y=>0), p1=>Point2d->new(x=>-1,y=>0));
    is_deeply($l1, $l2, 'simple perpendicularity');
   
    # bisector:
    $l1 = Line2d->bisector(p1=>Point2d->new(x=>0,y=>0), p2=>Point2d->new(x=>2, y=>2));
    $l2 = Line2d->new(p0=>Point2d->new(x=>1,y=>1), p1=>Point2d->new(x=>-1,y=>1));
    is_deeply($l1, $l2, 'bisector');

    # closest_t:
    $l = Line2d->new(p0 => Point2d->new(x=>0, y=>0), p1 => Point2d->new(x=>1, y=>0));
    my $x = rand;
    my $y = rand;
    $p0 = Point2d->new(x=>$x, y=>$y);
    my $t = $l->closest_t($p0);
    is ($t, $x, 'closest with horizontal line and random point');

#    $l = random_line();
# this isn't true...    is_deeply ($l->at($l->closest_t($p0)), $p0, 'at() and closest_t() are inverse');
# although you could do something clever with midpoints and bisectors....

    # x and y intercepts and join:
    $l = Line2d->vector(Point2d->new(x=>0,y=>2),Point2d->new(x=>2,y=>0));
    is ($l->x_intercept, undef, 'x-intercept');
    is ($l->y_intercept, 2, 'y-intercept');
    is ($l->slope, 0, 'slope');

    do {($x,$y)=(rand,rand)} until $x!=0;
    $l = Line2d->join(Point2d->new(x=>0, y=>0), Point2d->new(x=>$x,y=>$y));
    is ($l->x_intercept, 0, 'x-intercept');
    is ($l->y_intercept, 0, 'y-intercept');
    is ($l->slope, $y/$x, 'slope');
    
    $l = Line2d->new(p0=>Point2d->new(x=>1,y=>4), p1=>Point2d->new(x=>1,y=>1));
    is ($l->x_intercept, -3, 'x-intercept');
    is ($l->y_intercept, 3, 'y-intercept');
    is ($l->slope, 1, 'slope');

    $l = Line2d->new(p0=>Point2d->new(x=>1,y=>4), p1=>Point2d->new(x=>1,y=>0));
    is ($l->x_intercept, undef, 'x-intercept');
    is ($l->y_intercept, 4, 'y-intercept');
    is ($l->slope, 0, 'slope');

    $l = Line2d->new(p0=>Point2d->new(x=>1,y=>4), p1=>Point2d->new(x=>0,y=>1));
    is ($l->x_intercept, 1, 'x-intercept');
    is ($l->y_intercept, undef, 'y-intercept');
    is ($l->slope, undef, 'slope');

    # Point2d::inside
    my @pts;
    push @pts, Point2d->new(x=>1, y=>0);
    push @pts, Point2d->new(x=>1, y=>1);
    push @pts, Point2d->new(x=>2, y=>-2);
    push @pts, Point2d->new(x=>3, y=>3);
    push @pts, Point2d->new(x=>-3, y=>3); # has no x_intercept
    push @pts, Point2d->new(x=>-3, y=>-3);
    push @pts, Point2d->new(x=>1, y=>-3);
    
    my $pt = Point2d->new(x=>0, y=>0);
    ok($pt->inside(\@pts), 'origin inside polygon');

    $pt = Point2d->new(x=>100, y=>rand(4));
    ok(!$pt->inside(@pts), 'x=100 not in polygon');

    $pt = Point2d->new(x=>1, y=>-1);
    ok(!$pt->inside(@pts), '(1,-1) not in polygon');

    # Clockwise:
    $p0=Point2d->new(0,0);
    $p1=Point2d->new(0,0);
    $p2=Point2d->new(0,0);
    ok(!Point2d::clockwise($p0,$p1,$p2),'cw same point');

    # horizontal
    $p1=Point2d->new(-1,0);
    $p2=Point2d->new(1,0);
    ok(!Point2d::clockwise($p0,$p2,$p1),'cw linear');
    ok(!Point2d::clockwise($p0,$p2,$p1),'cw linear');

    $p0=Point2d->new(0,1);
    ok(Point2d::clockwise($p0,$p2,$p1),'ccw');
    ok(!Point2d::clockwise($p0,$p1,$p2),'ccw');

    # vertical
    $p0=Point2d->new(0,1);
    $p1=Point2d->new(0,0);
    $p2=Point2d->new(1,0);
    ok(!Point2d::clockwise($p0,$p1,$p2),'ccw vertical');
    $p2=Point2d->new(-1,0);
    ok(Point2d::clockwise($p0,$p1,$p2),'cw vertical');

    ok(Point2d::clockwise(Point2d->new(0,0),Point2d->new(1,1),Point2d->new(1,0)),'cw');
    ok(!Point2d::clockwise(Point2d->new(0,0),Point2d->new(1,0),Point2d->new(1,1)), 'ccw');

    ok(Point2d::clockwise(Point2d->new(2,6),Point2d->new(-4,5),Point2d->new(0,10)),'cw');
    ok(!Point2d::clockwise(Point2d->new(2,6),Point2d->new(-4,5),Point2d->new(0,-10)),'ccw');


    # Functors:
    $l = Line2d->new(1,2,2,6);
    my $f=$l->as_function_t;
    is(ref $f,'CODE','got a coderef');
    do { ok(&$f($_)->equals($l->at($_)),'functor test with t'); } for (1,4,0,-1,6);

    $f=$l->as_function_xy;
    is(ref $f,'CODE','got a coderef');
    is(&$f(0),$l->y_intercept,'functor xy intercept');
    is(&$f(1),2,'functor xy intercept');
    is(&$f(3),8,'functor xy intercept');
}

sub random_line {
    return Line2d->new(p0 => random_point(), p1 => random_point());
}

sub random_point {
    return Point2d->new(x => rand, y => rand);
}
