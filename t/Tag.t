#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use FindBin;
use Options;
use Test::More qw(no_plan);
use lib '../..';
use PhonyBone::TaggableA::Image;

use vars qw($tag_class $image_class $file_class);

BEGIN: {
  Options::use(qw(d create_table));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $tag_class='PhonyBone::Tag';
    $image_class='PhonyBone::TaggableA::Image';
    $file_class='PhonyBone::TaggableA::File';
}

use PhonyBone::Tag;
MAIN: {
    require_ok($tag_class) or die "errors loading class '$tag_class': $!\n";

    if ($options{create_table}) {
	$tag_class->create_table(drop_first=>1);
	$file_class->create_table(drop_first=>1);
	$image_class->create_table(drop_first=>1);
    }

    # setup an image object and a file object:
    my $image=$image_class->new(path=>'/home/vcassen/bad_day.jpg');
    isa_ok($image,$image_class);
    $image->store;
    ok($image->primary_id>0,'got primary_id for image') or die Dumper $image;

    my $file=$file_class->new(path=>'/home/vcassen/opera6.adr');
    $file->store;
    ok(length $file->primary_id>0,'got primary_id for file: '.$file->primary_id);
    
    # setup some info for tags:
    my %tag_info=(rider=>'Johnny Speedmaster',
		  bike=>'Yamaha TZ250',
		  date=>'2-12-43',
		  );
    my %tag_hash=map {($_,$tag_class->new(tag_name=>$_,tag_value=>$tag_info{$_}))} keys %tag_info;

    # tag the image w/each tag:
    while (my ($tag_name,$tag)=each %tag_hash) {
	isa_ok($tag,$tag_class,"got a tag object back from \$image->tag ($tag_name)");
	$image->tag($tag);
    }

    my $tags=$tag_class->tags($image);
    foreach my $tag (@$tags) {
	my ($tag_name,$tag_value)=($tag->tag_name,$tag->tag_value);
	is($tag_info{$tag_name},$tag_value,"got $tag_name=$tag_value");
    }

    my $obj_ids=$tags->[0]->object_ids;
 #   warn "obj_ids are ",Dumper($obj_ids); 
    $obj_ids=$tag_class->new(tag_name=>'rider',tag_value=>'Johnny Speedmaster')->object_ids;
#    warn "obj_ids are ",Dumper($obj_ids); 
					
    dup_tags($image);
}

sub dup_tags {
    my ($obj)=@_;
    my ($tag,%tags);

    # add some ambigous tags:
    $tag=$obj->tag(tag_name=>'rider');
    $tags{$tag->tag_id}=$tag;
    $tag=$obj->tag(tag_name=>'rider',tag_value=>'fred');
    $tags{$tag->tag_id}=$tag;
    $tag=$obj->tag(tag_name=>'rider',tag_value=>'wilma');
    $tags{$tag->tag_id}=$tag;

    # get tags back for object; should be at least three:
    my @tags=$tag_class->tags($obj);
    foreach $tag (@tags) {
#	ok($tags{$tag->tag_id}, "got tag ".$tag->tag_id) or next;
	delete $tags{$tag->tag_id};
    }
    is(scalar keys %tags,0,'got all tags (none left over)');

    # search for objects based on tag_name:
}
