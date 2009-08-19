#!/usr/bin/perl -w
use strict;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use PhonyBone::Persistable::File;

use vars qw($class $file_class);

BEGIN: {
  Options::use(qw(d));
    Options::get();
    $ENV{DEBUG}=$options{d} if defined $options{d};
    $class='PhonyBone::OrderedList';
    $file_class='PhonyBone::Persistable::File';
}

MAIN: {
    require_ok($class) or die "errors loading class '$class': $!\n";

    # add_before:
    my $l1=$class->new;
    $l1->add_before(item=>'fred',id=>'fred');
    is($l1->first_id,'fred','set first');
    is($l1->last_id,'fred','set last');
    is(join(',',$l1->all_ids),'fred','all_ids == "fred"');

    $l1->add_before(item=>'wilma',id=>'wilma'); # no 'before'->add to start of list
    is($l1->first_id,'wilma','wilma is first');
    is($l1->last_id,'fred','fred now last');
    my $all_ids=$l1->all_ids;
    is(join(',',$l1->all_ids),'wilma,fred','all_ids == "wilma,fred"');

    $l1->add_before(item=>'barny',id=>'barny',before=>'fred');
    is($l1->last_id,'fred','fred still last');
    is($l1->first_id,'wilma','wilma still first');
    is(join(',',$l1->all_ids),'wilma,barny,fred','all_ids == "wilma,barny,fred"');

    $l1->add_before(item=>'betty',id=>'betty',before=>'fred');
    is($l1->last_id,'fred','fred still last');
    is($l1->first_id,'wilma','wilma still first');
    is(join(',',$l1->all_ids),'wilma,barny,betty,fred','all_ids == "wilma,barny,betty,fred"');

    $l1->add_front(item=>'pebbles',id=>'pebbles');
    is($l1->first_id,'pebbles','pebbles now first');
    is($l1->last_id,'fred','fred still last');
    is(join(',',$l1->all_ids),'pebbles,wilma,barny,betty,fred','all_ids == "pebbles,wilma,barny,betty,fred"');

    $l1->add_end(item=>'bam bam',item_id=>'bam bam');
    is($l1->first_id,'pebbles','pebbles still first');
    is($l1->last_id,'bam bam','bam bam still last');
    is(join(',',$l1->all_ids),'pebbles,wilma,barny,betty,fred,bam bam','all_ids == "pebbles,wilma,barny,betty,fred,bam bam"');

    # add_after
    my $l2=$class->new;
    $l2->add_after(item=>'fred',id=>'fred');
    is($l2->first_id,'fred','set first');
    is($l2->last_id,'fred','set last');
    is(join(',',$l2->all_ids),'fred','all_ids == "fred"');

    $l2->add_after(item=>'wilma',id=>'wilma'); # no 'before'->add to end of list
    is($l2->last_id,'wilma','wilma is last');
    is($l2->first_id,'fred','fred now first');
    $all_ids=$l2->all_ids;
    is(join(',',$l2->all_ids),'fred,wilma','all_ids == "wilma,fred"');

    $l2->add_after(item=>'barny',id=>'barny',after=>'fred');
    is($l2->first_id,'fred','fred still first');
    is($l2->last_id,'wilma','wilma still last');
    is(join(',',$l2->all_ids),'fred,barny,wilma','all_ids == "wilma,barny,fred"');

    $l2->add_after(item=>'betty',id=>'betty',after=>'fred');
    is($l2->first_id,'fred','fred still first');
    is($l2->last_id,'wilma','wilmastill last');
    is(join(',',$l2->all_ids),'fred,betty,barny,wilma','all_ids == "wilma,barny,betty,fred"');
    is($l2->id_before('betty'),'fred','fred comes before betty');
    is($l2->id_after('fred'),'betty','betty comes after fred');

    # add_front and add_end:
    my $l3=$class->new(ids_only=>1);
    $l3->add_front(id=>'red');
    is($l3->first_id,'red','red first');
    is($l3->last_id,'red','red last');
    is(join(',',$l3->all_ids),'red','all_ids == "red"');

    $l3->add_front(id=>'blue');
    is($l3->first_id,'blue','blue first');
    is($l3->last_id,'red','red last');
    is(join(',',$l3->all_ids),'blue,red','all_ids == "blue,red"');

    my $l4=$class->new(ids_only=>1);
    $l4->add_end(id=>'red');
    is($l4->first_id,'red','red first');
    is($l4->last_id,'red','red last');
    is(join(',',$l4->all_ids),'red','all_ids == "red"');

    $l4->add_end(id=>'blue');
    is($l4->first_id,'red','red first');
    is($l4->last_id,'blue','blue last');
    is(join(',',$l4->all_ids),'red,blue','all_ids == "red,blue"');

    my $l5=$class->new;
    eval {$l5->add_end(item=>'red')}; # this is ok; $id <- 'red'
    is($@,'');
#    like($@,qr'non-ref .* passed to list that expects objects','trapped id passed to list expecting objects (missing object)');

    eval{$l5->add_front(item=>'red',id=>'blue')}; 
    is($@,'','no error adding two scalars');
    is($l5->first_id,'blue','got id');
    my $item=$l5->first_item;
    is($item,'red','got item');

    eval{$l5->add_end(item=>{})};
    like($@,qr"doesn't define primary_id",'trapped id passed to list expecting objects (item not an object)');

    eval{$l5->add_end(item=>'red',id=>{})};
    like($@,qr"not a scalar",'trapped id not a scalar');

    my $file=$file_class->new();
    eval{$l5->add_end(item=>$file)};
    like($@,qr"doesn't have a primary id",'trapped missing primary_id (missing from object)');

    eval{$l5->add_end(item=>$l4)};
    like($@,qr"doesn't define primary_id","trapped missing primary_id (class doesn't define method)");
    
    eval{$l5->add_after(item=>$l4)};
    like($@,qr"doesn't define primary_id","trapped missing primary_id (class doesn't define method)");
    
}
