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
our $class1='Person';
our $class2='Motorcycle';

use lib "$Bin";
use TestPerson;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class1) or BAIL_OUT("$class1 has compile issues, quitting");
    require_ok($class2) or BAIL_OUT("$class2 has compile issues, quitting");
    $class1->db_name('test_person');
    $class1->delete_all;
    $class2->db_name('test_mc');
    $class2->delete_all;

    my $person=new Person(firstname=>'Penelope', lastname=>'Cruz', age=>20);
    $person->save;
    isa_ok($person->_id, 'MongoDB::OID', "$person saved");

    my $bike=new Motorcycle(make=>'KTM', model=>'SMC625', ccs=>625, year=>2004);
    $bike->save;
    isa_ok($bike->_id, 'MongoDB::OID', "$bike saved");

    my $p_clone=$class1->find({_id=>$person->_id})->[0];
    isa_ok($p_clone, $class1, "got clone $p_clone");
    my $p_recs=$class1->mongo->find; # tike ole of em!
    isa_ok($p_recs, 'MongoDB::Cursor');
    my @people=$p_recs->all;
    cmp_ok(@people, '==', 1);
    my %unblessed=%$p_clone;
    is_deeply($people[0], \%unblessed);

    my $b_clone=$class2->find({_id=>$bike->_id})->[0];
    isa_ok($b_clone, $class2, "got clone $b_clone");
    my $b_recs=$class2->mongo->find; # tike ole of em!
    isa_ok($b_recs, 'MongoDB::Cursor');
    my @garage=$b_recs->all;
    cmp_ok(@garage, '==', 1);
    %unblessed=%$b_clone;
    is_deeply($garage[0], \%unblessed);

    warn "done\n";
#    my $testcase=new TestMultiDBs();
}



main(@ARGV);

