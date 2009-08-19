#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Root;
use Line2d;
use Point2d;
#require 'combinations.pl';
use Math::Combinatorics;
require 'snippets/files.pl';

use constant DEFAULT_SW=>1;

MAIN: {
    # read command line
  Options::use(qw(d sw=s all axis lower=i upper=i n=i h=i));
    Options::useDefaults(h=>1, sw=>DEFAULT_SW);
    Options::get();
    $ENV{DEBUG}=1 if $options{d};

    # further argument processing
    if ($options{all}) {
	$options{lower}=2;
	$options{upper}=$n_points;
    }
    if ($options{n}) {
	$options{lower}=$options{n} unless $options{lower};
	$options{upper}=$options{n} unless $options{upper};
    }

    # read points
    my $filename = shift @ARGV or die "no filename\n";
    my ($points,$vectors) = read_points($filename);
    my $n_points = @$points;
    die "not enough points" if scalar @$points < 2;
    my $h=$options{h};
    die "bad/negative h: $h\n" if $vectors && $h<=0;

    my $lower=$options{lower}? $options{lower}:$options{upper}? 2:$n_points;
    my $upper=$options{upper}? $options{upper}:$n_points;

    # process file, doing all timepoints and increments (phew!)
    my $js=init_js($options{h});
    while ($h--) {
	my $bisectors=process_file($filename,$points,$upper,$lower);
	if ($vectors) {
	    move_points($points,$vectors);
	    $js.=js_block($points,$bisectors);
	}
    }
    $js.=finish_js();

    my $js_filename="${filename}_data.js";
    spitString($js,$js_filename);
    warn "$js_filename written\n";
}

sub process_file {
    my ($filename,$points,$upper,$lower)=@_;
    my $n_points=@$points;

    # generate all bisectors
    warn "making bisectors\n";
    my $bisectors=make_bisectors($points);

    # generate, sort all possible int_keys
    warn "making intersections\n";
    my $intersections=make_intersections($n_points,$filename);
    warn "intersections made\n";

#    warn "lower is $lower, upper is $upper\n";
    for (my $n=$lower; $n<=$upper; $n++) {
	warn "making map $n\n";
	make_map($points,$bisectors,$intersections,$n,$filename);
    }
    $bisectors;
}

sub move_points {
    my ($points,$vectors)=@_;
    my $n=@$points;
    my $v=@$vectors;
    confess "corrupt vectors (n=$n, v=$v)" unless $n==$v;
    while ($n--) {
	my $p=$points->[$n];
	$p->{x}+=$vectors->[$n]->{x};
	$p->{y}+=$vectors->[$n]->{y};
    }
}


sub make_map {
    my ($points,$bisectors,$intersections,$n_points,$filename)=@_;
    clear_bisectors($bisectors);

    # clip bisectors in order of int keys
    clip_bisectors($bisectors,$points,$intersections,$n_points);

    # print bisectors
    print_bisectors($bisectors,$n_points) if $options{d};

    # create svg file (only need to do this the first time!
    svg(bisectors=>$bisectors, points=>$points, filename=>$filename, n=>$n_points);
}

sub clear_bisectors {
    my $bisectors=shift;
    foreach my $b (values %$bisectors) {
	$b->clear_ts;
    }
}

sub read_points {
    my $filename = shift or confess "no filename";
    my @points;
    my @vectors;

    open (INPUT, $filename) or die "Can't read $filename: $!\n";
    my $lineno=1;
    while (<INPUT>) {
	chomp;
	my @coords=/([-.\d]+)/g;
	if (@coords==2) {
	    push @points, Point2d->new(x=>$coords[0],y=>$coords[1]);
	} elsif (@coords==4) {
	    push @points, Point2d->new(x=>$coords[0],y=>$coords[1]);
	    push @vectors, Point2d->new(x=>$coords[2],y=>$coords[3]);
	} else {
	    confess "bad line $lineno: $_\n";
	}
	$lineno++;
    }
    close INPUT;
    my $n_points=@points;
    foreach my $n (0..$n_points-1) {
	my $w= "$n: ".$points[$n]->as_string;
	$w.=' v='.$vectors[$n]->as_string if @vectors;
	warn "$w\n";
    }
    return (\@points,\@vectors);
}

sub make_bisectors {
    my ($points)=@_;
    my $n=@$points;
    my $bisectors={};

    for (my $i=0; $i<$n; $i++) {
	for (my $j=$i+1; $j<$n; $j++) {
	    my $key=join('_',($i,$j));
	    $bisectors->{$key}=Line2d->bisector(p1=>$points->[$i],p2=>$points->[$j]);
	    $bisectors->{$key}->{key}=$key;
	}
    }
    $bisectors;
}


sub make_intersections {
    my ($n_points,$filename)=@_;

    if (open(FILE,"$filename.int")) {
	my $dump=join('',<FILE>);
	close FILE;
	my $VAR1;
	eval $dump;
	return $VAR1;
    }

    my @subsets=combine(3,(0..$n_points-1));
    my @intersections=map {join('_',@$_)} @subsets;

    open(FILE, ">$filename.int") or die "Can't open $filename.int for writing: $!\n";
    print FILE Dumper(\@intersections);
    close FILE;
    warn "$filename.int written\n";

    \@intersections;
}


sub min { 
    my $min=Root::VERY_LARGE;
    foreach (@_) { $min=$_ if $_<$min; }
    $min;
}

sub max { 
    my $max=-Root::VERY_LARGE;
    foreach (@_) { $max=$_ if $_>$max; }
    $max;
}


sub clip_bisectors {
    my ($bisectors,$points,$intersections,$n_points)=@_;

    foreach my $int_key (@$intersections) {
	my ($i,$j,$k)=split('_',$int_key);
	next if $k>=$n_points;
#	warn "i=$i, j=$j, k=$j (from $int_key)\n";

	my $bij=$bisectors->{"${i}_$j"};
	my $bik=$bisectors->{"${i}_$k"};
	my $bjk=$bisectors->{"${j}_$k"};
	next if ($bij->invalid && $bik->invalid && $bjk->invalid);

	# find intersections points via $t's:
	my ($tij1,$tik1)=$bij->intersection2t($bik) if $bij&&$bik;
	my ($tij2,$tjk1)=$bij->intersection2t($bjk) if $bij&&$bjk;
	my ($tik2,$tjk2)=$bik->intersection2t($bjk) if $bik&&$bjk;

	# clip each bisector unless parellel:
	# if they are parellel, remove the bisector between the two points that are the farthest away
	my $parellel=!(defined $tij1 && defined $tik1 && defined $tjk1) ||
	    !(very_close($tij1,$tij2) && very_close($tik1,$tik2) && very_close($tjk1,$tjk2));
	
	if (!$parellel) {
	    my $cw=Point2d::clockwise($points->[$i], $points->[$j], $points->[$k]);
	    my @subscript=$cw?qw(t0 t1 t0):qw(t1 t0 t1); # magic

	    $bij->clip($subscript[0],$tij1);
	    $bik->clip($subscript[1],$tik1);
	    $bjk->clip($subscript[2],$tjk1);

	} else {		# parellel
	    my $dij=$points->[$i]->distance_to($points->[$j]);
	    my $dik=$points->[$i]->distance_to($points->[$k]);
	    my $djk=$points->[$j]->distance_to($points->[$k]);
	    $bij->invalidate if ($dij>$dik && $dij>$djk); # two extra comparisons, so sue me; only one will be invalidated
	    $bik->invalidate if ($dik>$dij && $dik>$djk);
	    $bjk->invalidate if ($djk>$dij && $djk>$dik);
	}
    }
}

sub very_close {
    my $diff=$_[0]-$_[1];
    $diff=-$diff if $diff<0;
    warn "very_close faild: diff is $diff\n" if $diff>Root::VERY_SMALL;
    return $diff<Root::VERY_SMALL;
}


sub print_bisectors {
    my ($bisectors,$n_points)=@_;
    foreach my $key (sort keys %$bisectors) {
	my ($i,$j)=split('_',$key);
	next if $j>=$n_points;
	my $b=$bisectors->{$key};
	print $b->as_string_segment,"\n";
    }
}

########################################################################
## svg-generating code:

sub svg {
    my %argHash=@_;
    my $points=$argHash{points} or confess "no points";
    my $bisectors=$argHash{bisectors} or confess "no bisectors";
    my $n_points=$argHash{n} || scalar @$points;
    my $filename=$argHash{filename} or confess "no filename";

    my $svg;
    my ($minx, $maxx, $miny, $maxy)=(+Root::VERY_LARGE,-Root::VERY_LARGE,+Root::VERY_LARGE,-Root::VERY_LARGE);
    my $id=0;
    my $sw=$options{sw};

    my $rad=$sw;
    my $fontsize=$sw*4;
    my $xoffset=$sw*2;
    my $yoffset=$sw;
    for (my $n=0; $n<$n_points; $n++) {
	my $p=$points->[$n];
	$svg.=$p->svg(radius=>$rad,id=>"point_".$id)."\n"; 
	my $t=sprintf "transform='scale(1,-1) translate(%.2g,%.2g)",$p->{x},-$p->{y};
	$svg.=sprintf "<text x='$xoffset' y='$yoffset' font-size='$fontsize' $t'>pt$id</text>\n" unless $options{h}>1;
	$minx=$p->{x} if $p->{x}<$minx;
	$maxx=$p->{x} if $p->{x}>$maxx;
	$miny=$p->{y} if $p->{y}<$miny;
	$maxy=$p->{y} if $p->{y}>$maxy;
	$id++;
    }
    my $pad=1.5;
    my $side=max(abs($minx),abs($miny),abs($maxx),abs($maxy));
    my $padded=$side*$pad;

    # do lines:
    foreach my $b (values %$bisectors) { 
	my ($i,$j)=split('_',$b->{key});
	next if $j>=$n_points;
	$b->{t0}=-10 unless defined $b->{t0};
	$b->{t1}=+10 unless defined $b->{t1};
	$svg.=$b->svg('stroke-width'=>$sw)."\n"; 
    }

    #prepend header:
    my $svg_root="<svg  xmlns='http://www.w3.org/2000/svg'\nxmlns:xlink='http://www.w3.org/1999/xlink'\n";
    $svg_root.="onload='svg_init()'\n";
    $svg_root.="viewBox='".join(' ',map{sprintf "%6.4g",$_} (-$padded,-$padded,$padded*2,$padded*2))."'>\n";
    $svg_root.="<script type='text/ecmascript' xlink:href='svg.js'/>\n";
    $svg_root.="<script type='text/ecmascript' xlink:href='${filename}_data.js'/>\n";
    # put in a transform to make coordinates normal (ie, positive y is up, not down):
    $svg_root.="<g transform='scale(1,-1)'>\n";

    if ($options{axis}) {
	my $axis="<!--axis-->\n<line x1='0' y1='$side' x2='0' y2='-$side' stroke='red' stroke-width='$sw'/>\n";
	$axis.="<line x1='$side' y1='0' x2='-$side' y2='0' stroke='red' stroke-width='$sw'/>\n";
	$svg_root.=$axis;
    }

    $svg.="</g>\n";
    $svg.="</svg>\n";

    $svg=$svg_root.$svg;

    if ($filename) {
	my $svgfile="$filename.svg";
	open (SVG, ">$svgfile") or confess "Can't open $svgfile: $!";
	print SVG $svg;
	close SVG;
	warn "*** $svgfile written ***\n";
    }
    $svg;
}

########################################################################
## js-generating code:

sub init_js {
    my $max_h=shift or confess "no max_h";
    "var max_h=$max_h;\ntimedata=[\n";
}

sub js_block {
    my ($points,$bisectors)=@_;

    my $js="{ points: [\n";
    my $n=0;
    my @ps;
    foreach my $p (@$points) {
	push @ps,$p->as_js(id=>"point_$n");
	$n++;
    }
    $js.=join(",\n",@ps);
    $js.="\n],\n";

    $js.="  lines: {\n";
    my %bs;
    my $sw=$options{sw};
    while (my ($bi_key,$b)=each %$bisectors) {
	$js.=$b->as_js;
	$js.=",\n";
    }
    $js.="}\n},\n";
    $js;
}

sub finish_js {
    "];\n";
}
