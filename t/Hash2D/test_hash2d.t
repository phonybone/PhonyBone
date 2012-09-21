#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../..");
our $class;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    $class=shift @ARGV or die usage('class');
}

sub main {
    my (@args)=@_;
    require_ok($class);
    test_basic();
}

# build a fixture Hash2D:
sub h2 {
    my %args=@_;
    $args{row_major}=0;
    my $h2=$class->new(%args);

    # put
    $h2->put('Honda', 'Color', 'Red');
    $h2->put('Honda', 'Model', 'RCV211');
    $h2->put('Honda', 'Rider', 'Stoner');

    $h2->put('Yamaha', 'Color', 'Blue');
    $h2->put('Yamaha', 'Model', 'M1');
    $h2->put('Yamaha', 'Rider', 'Lorenzo');

    $h2->put('Suzuki', 'Color', 'Yellow');
    $h2->put('Suzuki', 'Model', 'GS550');
    $h2->put('Suzuki', 'Rider', 'Nobody');

    $h2->put('KTM', 'Color', 'Orange');
    $h2->put('KTM', 'Model', 'EXC450');
    $h2->put('KTM', 'Rider', 'Dungey');
    $h2;
}

sub test_basic {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my @x_axis=qw(Honda Yamaha Suzuki KTM);
    my @y_axis=qw(Color Model Rider);

    my $h2=h2(x_delim=>"\t", quote_elements=>0);

    # n_rows & n_cols:
    cmp_ok($h2->n_cols, '==', 4, "4 cols");
    cmp_ok($h2->n_rows, '==', 3, "3 rows");


    # axis's:
    is_deeply($h2->x_axis, [qw(Honda Yamaha Suzuki KTM)], 'x axis');
    is_deeply($h2->y_axis, [qw(Color Model Rider)], 'y axis');

    # get:
    cmp_ok($h2->get('Honda', 'Rider'), 'eq', 'Stoner', 'Stoner');
    cmp_ok($h2->get('Yamaha', 'Model'), 'eq', 'M1', 'M1');
    cmp_ok($h2->get('Suzuki', 'Color'), 'eq', 'Yellow', 'Yellow');
    is($h2->get('KTM', 'fart'), undef, 'undef 1');
    is($h2->get('fart', 'fart'), undef, 'undef 2');

    # as_str:
    my $expected=<<"    EXPECTED";
\tHonda\tYamaha\tSuzuki\tKTM
Color\tRed\tBlue\tYellow\tOrange
Model\tRCV211\tM1\tGS550\tEXC450
Rider\tStoner\tLorenzo\tNobody\tDungey
    EXPECTED
    cmp_ok($h2->as_str(include_headers=>1)."\n", 'eq', $expected, 'as_str(include_headers=>1)');

    $expected=<<"    EXPECTED";
Red\tBlue\tYellow\tOrange
RCV211\tM1\tGS550\tEXC450
Stoner\tLorenzo\tNobody\tDungey
    EXPECTED
    cmp_ok($h2->as_str."\n", 'eq', $expected, 'as_str');

}

sub test_quote {
    my $h2=h2(x_delim=>"\t");
    
}

main(@ARGV);

