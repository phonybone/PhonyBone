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
our $class='PhonyBone::FileUtilities';
use PhonyBone::FileUtilities qw(spitString slurpFile substitute);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);		# redundant
    my $fn='substitute.txt';
    unlink $fn, "$fn.bak";
    my $haiku=<<"    HAIKU";
Yesterday it worked.
Today it is not working.
Windows is like that.
    HAIKU

    spitString($haiku, $fn);
    substitute($fn, 'work', 'fart');
    ok(-r "$fn.bak");
    my $new_haiku=slurpFile($fn);
    $new_haiku=~s/fart/work/msg;
    is($new_haiku, $haiku);
}

main(@ARGV);

