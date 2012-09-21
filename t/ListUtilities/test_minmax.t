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

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $sub=\&{"${class}::minmax"};
    
    my @l=qw(1 2 3 4);
    is_deeply([$sub->(@l)], [1, 4]);

    warn Dumper([$sub->(qw(10 2 3 fred wilma 4f))]);
}

main(@ARGV);

