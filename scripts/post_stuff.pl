#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use URI::Escape;

use lib '/home/vcassen/sandbox/perl';
use PhonyBone::TaggableA::File;
use PhonyBone::Tag;
use PhonyBone::FileUtilities qw(basename suffix);

my %suffix2type=(
		 txt=>'text',
		 jpg=>'image',
		 jpeg=>'image',
		 gif=>'image',
		 png=>'image',
		 xml=>'xml',
		 pl=>'perl script',
		 pm=>'perl module',
		 t=>'test',
		 c=>'c code',
		 cc=>'c++ code',
		 gcc=>'c++ code',
		 zip=>'zipped file',
		 gz=>'gzipped data',
		 tgz=>'gzipped tar file',
		 html=>'html',
		 xhtml=>'html',
		 css=>'css',
		 js=>'javascript',
		 doc=>'MS Word Doc',
		 );


BEGIN: {
  Options::use(qw(d q v h url=s method=s src_dir=s filter_re=s class=s tag_files=s
		  fuse=i get_dir=s tag_name=s tag_value=s));
    Options::useDefaults(url=>'http://vcassen.t1dbase.org/cgi-bin/tag_service.cgi',
			 method=>'GET',
#			 src_dir=>'/home/vcassen/random/images',
			 filter_re=>'.',
			 fuse=>-1,
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

MAIN: {
    my $ua=LWP::UserAgent->new;
    my $baseurl=$options{url};

    
    if ($options{src_dir}) {
	my $files_xml=post_dir_files($ua,$baseurl);
	warn $files_xml;
    }

    if ($options{tag_files}) {
	tag_files($options{tag_files},$ua,$baseurl);
    }
    
    if (my $dir=$options{get_dir}) {
	my $xml=get_dir($dir,$ua,$baseurl);
	warn $xml;
    }

}

# given a directory ($options{src_dir}), filtered by $options{filter_re}, 
# POST a request to the tag_service (defined by $options{url}) inserting
# each file in the directory.
sub post_dir_files {
    my ($ua,$baseurl)=@_;
    # get files from src_dir:
    my $re=qr($options{filter_re});
    opendir (DIR,$options{src_dir}) or die "Can't read directory '$options{src_dir}': $!\n";
    my @files=grep /$re/, readdir DIR;
    closedir DIR;
    warn "files are ",Dumper(\@files) if $options{v};
    warn sprintf("%d files\n", scalar @files) unless $options{v};

    # insert things one at a time:
    my $url="$baseurl/file";
    my $fuse=$options{fuse};
    my $xml_sum="<objs>\n";
    foreach my $file (@files) {
	my $path=$options{src_dir}."/$file";
	my $type=filetype($path)||'file';
	my $owner=getpwuid((stat $path)[4])||$ENV{USER};
	my $tag_file=PhonyBone::TaggableA::File->new(path=>$path,
						     owner=>$owner,
						     ftype=>$type,
						     );
	my $xml=$tag_file->xml;
	my $req=HTTP::Request->new('POST',$url,undef,$xml);
	my $res=$ua->request($req);
	warn "$file: ",$res->status_line, "\n";
#	warn "$file: content is ",$res->content;
	$xml_sum.=$res->content;
	last if --$fuse==0;
    }
    $xml_sum.="</objs>\n";
}

sub tag_files {
    my ($dir,$ua,$baseurl)=@_;
    my $file_xml=get_dir($dir,$ua,$baseurl);
    my $tag_name=$options{tag_name} or die "no tag_name\n";
    my $tag_value=$options{tag_value} or die "no tag_value\n";
    my $res_xml;
    my $fuse=$options{fuse};
    my @file_ids=$file_xml=~/tag_file_id="(\d+)"/msg;

    foreach my $file_id (@file_ids) {
#	warn "file_id is $file_id";
	my $tag=PhonyBone::Tag->new(tag_name=>$tag_name,
				    tag_value=>$tag_value,
				    obj_eid=>$file_id,
				    obj_class=>'PhonyBone::Taggable::File');
	warn "tag->xml is ",$tag->xml;
	my $req=HTTP::Request->new('POST',"$baseurl/tag",undef,$tag->xml);
	my $res=$ua->request($req);
	warn "$baseurl/tag: ",$res->status_line,($res->is_error? $res->content:'');
	$res_xml.=$res->content if $res->is_success;
	last if --$fuse==0;
    }
}

sub tag_value_code {
    my ($dir,$ua,$baseurl)=@_;
    my $file_xml=get_dir($dir,$ua,$baseurl);
    my $tag_name=$options{tag_name} or die "no tag_name\n";

    my $fuse=$options{fuse};
    

}

# returns xml describing all file objects in a given directory
sub get_dir {
    my ($dir,$ua,$baseurl)=@_;
    $dir=~s|/|\\|g;
    my $url="$baseurl/file/attrs/path/like/$dir*";
    my $req=HTTP::Request->new('GET',$url);
    my $res=$ua->request($req);
    $res->content;
}

sub filetype {
    my $file=shift;
    $file=~s/ /\\ /g;
    my $suffix=suffix($file);
    my $type=$suffix2type{lc $suffix};
    return $type if $type;
    $type=`file $file`;
    chomp $type;
    $type=~s/\w*: //;
    return 'image' if $type=~/JPG|JPEG|GIF|PNG/i;
    return 'directory' if $type=~/directory/i;
    return 'text' if $type=~/text/i;
    $type;
}












