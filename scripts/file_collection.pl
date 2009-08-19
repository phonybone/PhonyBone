#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileCollection;
use PhonyBone::Persistable::File;

use FindBin;
require "$FindBin::Bin/snippets/get_files.pl";

BEGIN: {
  Options::use(qw(d h filter_re=s server=s doc_root=s create_table 
		  dir=s collection_id=s collection_name=s file_id=s delete));
    Options::useDefaults(
			 server=>'www.pnwmom.org',
			 filter_re=>qq(jpg|JPG\$), # fscking indenting
			 doc_root=>'/home/pnwmomor/public_html',
			 dir=>'/home/pnwmomor/public_html/galleries/archives',
			 file_id=>[],
			 );
    Options::get();
    die usage() if $options{h};
    $ENV{DEBUG}=1 if $options{d};
    $SIG{__DIE__}=sub { confess @_ };
}

MAIN: {
    my $dummy;
    PhonyBone::FileCollection->create_table(drop_first=>1) if $options{create_table};

    # limited operations:
    if ($options{delete}) {
	my $fc;
	if ($options{collection_name}) {
	    $fc=PhonyBone::FileCollection->new(collection_name=>$options{collection_name})->fetch;
	} elsif ($options{collection_id}) {
	    $fc=PhonyBone::FileCollection->new(collection_id=>$options{collection_id})->fetch;
	} else {
	    die "no file_collection specified\n";
	}
	die "no such file_collection\n" unless $fc;

	foreach my $file_id (@{$options{file_id}}) {
	    $fc->delete_file(file_id=>$file_id);
	}
	$fc->update;
	warn Dumper($fc) if $ENV{DEBUG};
	my $n_files=scalar @{$options{file_id}};
	my $n_left=$fc->n_items;
	warn "attempted to remove $n_files files ($n_left left)\n";
	exit;
    }
    
    # getters:
    if (my $collection_id=$options{collection_id}) {
	my $fc=PhonyBone::FileCollection->new(collection_id=>$collection_id)->fetch;
	die Dumper($fc);
    }

    my $fc_name=$options{collection_name};
    if ($fc_name && !$options{dir}) {
	my $fc=PhonyBone::FileCollection->new(collection_name=>$fc_name)->fetch;
	die Dumper($fc);
    }

    # create and store a collection (delete any of the same name first):
    die "no collection_name\n" unless $fc_name;
    my $fc0=PhonyBone::FileCollection->new(collection_name=>$fc_name);
    $fc0->delete;

    my $dir=$options{dir} or die "$0: no directory given\n";
    die "$dir: not a directory\n" unless -d $dir;
    die "$dir: not readable\n" unless -r $dir;

    $dir=fix($dir);
    my $fc=PhonyBone::FileCollection->new(collection_name=>$fc_name);

    my $re=$options{filter_re};
    opendir(DIR,$dir) or die "Can't open '$dir': $!\n";
    my @files=grep /$re/, readdir DIR;
    closedir DIR;
    warn sprintf "%d files to insert in $dir\n",scalar @files;

    foreach my $f (@files) {
	my $path="$dir/$f";
	# error: next line returns a File even if $path points to an Image
#	my $file=PhonyBone::Persistable::File->fetch(path=>$path);
	my $file=PhonyBone::Persistable::File->new_file(path=>$path)->fetch;
#	$file=$file->fetch;
	if (!$file) {
	    $file=PhonyBone::Persistable::File->new_file(path=>$path);
	    $file->set_url(%options);
	    $file->store;
	}
	$fc->append_file($file);# adds file to end of list
    }
    $fc->store;

    my $fc_id=$fc->collection_id;
    warn sprintf "fc_id is $fc_id; %d files\n", $fc->n_items;
    my $fc2=PhonyBone::FileCollection->new(collection_id=>$fc_id)->fetch;
    warn "fc2 is $fc2\n",Dumper($fc2) if $ENV{DEBUG};
}

