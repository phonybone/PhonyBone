#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/../..");
our $class='PhonyBone::ListUtilities';
use PhonyBone::ListUtilities qw(first_n last_n);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
#    test_first();
#    test_last();
    test_mixed();
}

sub test_first {
    my $list=[qw(1 2 3 4 5 6 7 8 9 10)];

    my $l=first_n($list, 1);
    is_deeply($l, [qw(1)]);

    $l=first_n($list, 2);
    warn "l is ",Dumper($l);
    is_deeply($l, [qw(1 2)]);

    $l=first_n($list, 10);
    is_deeply($l, $list);

    $l=first_n($list, 12);
    is_deeply($l, $list);
}

main(@ARGV);

