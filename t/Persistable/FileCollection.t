#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use PhonyBone::Persistable::File;

use vars qw($class $file_class);

BEGIN: {
  Options::use(qw(d create_table));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $class='PhonyBone::FileCollection';
    $file_class='PhonyBone::Persistable::File';
}

MAIN: {
    require_ok($class) or die "errors loading class '$class': $!\n";
    my $dbh=$class->dbh;
    isa_ok($dbh,'DBI::db','got the dbh');
    $class->create_table(drop_first=>1) if $options{create_table};
    
    my $fc=$class->new;
    isa_ok($fc,$class,"got a $class");
    my $file=$file_class->new(url=>'http://www.pnwmom.org/galleries/archives/32.JPG',
					     owner=>'victor',
					     mimetype=>'image/jpg');
    $fc->append_file($file);
    
    my $fc2=$class->new(ids_only=>1);
    $fc2->append_file($file);
    warn "fc2 are ",Dumper($fc2);
    my $item=$fc2->first_item;
    warn "item is ",Dumper($item);
    is(ref $item,$file_class,"got a $file_class back from first_item");
}
