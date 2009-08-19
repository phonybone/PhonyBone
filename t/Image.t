#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use FindBin;
use Options;
use Test::More qw(no_plan);

use PhonyBone::TaggableA::File;
use PhonyBone::TaggableA::Image;

use vars qw($class $file_class);

BEGIN: {
  Options::use(qw(d create_table));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $file_class='PhonyBone::TaggableA::File';
    $class='PhonyBone::TaggableA::Image';
}

MAIN: {
    require_ok($class) or die "errors loading class '$class': $!\n";
    my $image=$class->new(path=>'/home/vcassen/bad_day.jpg',
			  owner=>'vcassen');
    isa_ok($image,$class);
    warn Dumper($image);

    my $file=$file_class->new(path=>'/home/vcassen/random/whatever');

#    my $image_fields=$image->fields;
#    warn "image_fields are ",Dumper($image_fields);

    my $create_table=$options{create_table} || !$class->table_exists;
    $class->create_table if $create_table;
    $create_table=$options{create_table} || !$file_class->table_exists;
    $file_class->create_table if $create_table;
    

    warn "image is ",Dumper($image);
    $image->store;
    ok($image->primary_id>0, 'got image id after store: '.$image->primary_id);
    warn "file is ",Dumper($file);
    $file->store;
    ok($file->primary_id>0, 'got photo id after store: '.$image->primary_id);

    
}

