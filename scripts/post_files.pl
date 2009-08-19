#!/usr/bin/env perl 

########################################################################
## Script to post file objects to a tag server (tag server is sorta 
## misnamed, holds objects of any (implemented) type)
## 
## How to call:
## > post_filters.pl -src_server <src_server> -dst_server <dst_server> 
##   [src_dir|files] [-filter_re <filter_re>]
########################################################################

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use lib '/home/vcassen/sandbox/perl'; # for fala
use PhonyBone::Persistable::File;
use PhonyBone::Persistable::FileCollection;
use PhonyBone::Tag;
use PhonyBone::FileUtilities qw(basename suffix);
use WSFramework::TagClient;

use FindBin;
require "$FindBin::Bin/get_files.pl";
#require "$FindBin::Bin/snippets/get_files.pl";

# Usage:
# src_server: portion of url for file
# doc_root: used w/src_server to fully determine url of file (subtracted from @ARGV path
# dst_server: where we actually want to store the info (often 'localhost')
# 


BEGIN: {
  Options::use(qw(d q v h recur|r dst_server=s filter_re=s 
		  src_server=s doc_root=s collection=s
		  fuse=i ));
    Options::useDefaults(filter_re=>'[^.]',
			 fuse=>-1,
#			 src_server=>'http://vcassen.t1dbase.org/cgi-bin/tag_service.cgi',
			 src_server=>'http://www.pnwmom.org',
			 dst_server=>'localhost',
#			 doc_root=>'/home/vcassen/sandbox/perl/vcassen.t1dbase.org/htdocs',
			 doc_root=>'/home/victor/websites/www.pnwmom.org/',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

MAIN: {
    my $tc=get_tag_client();
    my @files=get_files(@ARGV);

    my $collection=make_collection(\@files) if $options{collection};

    my $fuse=$options{fuse};
    foreach my $file (@files) {
	post_file($tc,$file);
	last if --$fuse==0;
    }
}

sub get_tag_client {
    my $hostname=`hostname`;
    chomp $hostname;
    my $dst_server=$options{dst_server};
    my $type;
    if ($dst_server eq 'local' || $dst_server eq 'localhost') {
	$type='local';
    } elsif (index($dst_server,$hostname)>=0) {
	$type='local';
    } elsif (open(HOSTS,'/etc/hosts')) {
	my @hosts=map {(split(/\s+/))[1]} (grep /127.0.0.1/, <HOSTS>);
	foreach my $host (@hosts) {
	    if (index($dst_server,$host)>=0) {
		warn "got localhost $host\n";
		$type='local';
		last;
	    }
	}
    } else {
	$type='remote';
    }
    my $tag_client=WSFramework::TagClient->new(type=>$type);
}


sub post_file {
    my ($tc,$file)=@_;
    # create a file object for each file: url,owner,mimetype
    my $file_obj=PhonyBone::Persistable::File->from_path(path=>$file,
							 server=>$options{src_server},
							 doc_root=>$options{doc_root});
    eval {
	my $new_obj=$tc->post_obj(obj=>$file_obj,
				  server=>$options{dst_server},
				  debug=>0);
	warn $new_obj->url, " created\n";
    };
    warn $@ if $@;
    
}

sub make_collection {
    my ($files)=@_;
    my $collection=PhonyBone::Persistable::FileCollection->new(collection_name=>$options{collection});
    do {$collection->add_file($_)} @$files;
    $collection->store;
}
