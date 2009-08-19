#!/usr/bin/perl
# -*-perl-*- $Id: dbhmanager.t,v 1.2 2008/09/04 00:08:33 vcassen Exp $
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use vars qw($class);

BEGIN: {
    $class='PhonyBone::DBHManager';
    Options::use(qw(d h));
    Options::useDefaults();
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=$options{d} if defined $options{d};
}

MAIN: {
    use_ok($class);
    my $dbhm=$class->new;
    isa_ok($dbhm,$class,"got a $class");

    foreach my $class (qw(PhonyBone::TaggableA::File PhonyBone::Tag WSFramework::User)) {
	eval "require $class"; die $@ if $@;
	my $dbh;
	eval { $dbh=$dbhm->get_dbh($class) };
	is($@,'',"no error getting dbh for $class") and	isa_ok($dbh,'DBI::db',"got a dbh for $class");
    }
}
