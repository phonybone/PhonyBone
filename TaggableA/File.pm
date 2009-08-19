package PhonyBone::TaggableA::File;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use PhonyBone::FileUtilities qw(suffix);
use MIME::Types;
use MIME::Type;

########################################################################
##
## Name:      
## Author:    
## Created:   
## $Id: File.pm,v 1.15 2008/09/02 16:09:11 vcassen Exp $
##
## Description:
##
########################################################################


use base qw(PhonyBone::Persistable PhonyBone::TaggableA);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS %SYNONYMS);
@AUTO_ATTRIBUTES = qw(tag_file_id path url owner mimetype);
@CLASS_ATTRIBUTES = qw(tablename table_fields indexes uniques primary_key
		       type dbh);
%DEFAULTS = (tablename=>'taggable_file',
#	     table_fields=>{
#		 tag_file_id=>'INT PRIMARY KEY AUTO_INCREMENT',
#		 path=>'VARCHAR(255) NOT NULL',
#		 url=>'VARCHAR(255) NOT NULL',
#		 owner=>'VARCHAR(255) NOT NULL',
#		 mimetype=>'VARCHAR(255) NOT NULL DEFAULT "file"',
#	     },
	     indexes=>{url=>'VARCHAR(255)',
		       owner=>'VARCHAR(255)',
		   },
	     uniques=>[qw(url)],# TODO: make use of this
	     primary_key=>'tag_file_id',
	     type=>'file',
);

Class::AutoClass::declare(__PACKAGE__);

########################################################################
# Implement a factory constructor based on mimetype
our %mime2class=(
		image=>'PhonyBone::TaggableA::Image',
		);
sub new_file {			# now why couldn't this just be named 'new'?
    my ($self,%args)=@_;
    my $class=ref $self || $self;

    # find class based on mime-type; defaults to 
    if (my $mt=$args{mimetype} || $self->path2mimetype($args{path})) {
	$class=$mime2class{$mt};
	if (!$class) {
	    $mt=~s|/.*||;
	    $class=$mime2class{$mt};
	}
	if ($class) {
	    eval "require $class"; die $@ if $@;
	}
    }
#    warn "class is $class";
    $self=$class->new(%args);
}
########################################################################

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this

    # removed confession for when called by primary_id
    my $path=$self->path;# or confess "no path";
    $self->set_owner_from_path(path=>$path) if !$self->owner && $path;
    $self->set_mimetype_from_path(path=>$path) if !$self->mimetype && $path;
}

sub _init_class {
    my ($class)=@_;
    $class->set_dbh;
    PhonyBone::TaggableA::_init_class($class);
}

sub set_owner_from_path {
    my ($self,%argHash)=@_;
    my $path=$argHash{path} or return;
    my @s=stat $path;
    my $uid=$s[4];
    my $owner=getpwuid($uid)||$ENV{USER}||'nobody';
    $self->owner($owner);
}

sub set_mimetype_from_path {
    my ($self,%argHash)=@_;
    my $path=$argHash{path} or return;
    my $mt;
    my $suffix=suffix($path);
    if ($suffix) {
	$mt=MIME::Types->new->mimeTypeOf($suffix);
	$mt &&= $mt->simplified;
    } elsif (-d $path) {
	$mt='text/directory';
    }
    $self->mimetype($mt) if $mt;
}

########################################################################


# set the url based on a server/doc root combo
sub set_url {
    my ($self,%argHash)=@_;
    my $server=$argHash{server} or confess "no server";
    my $doc_root=$argHash{doc_root} or confess "no doc_root";
    
    my $url=$self->path or confess 'no path';
    $url=~s/$doc_root//;
    $url="$server/$url";
    $url=~s|///*|/|g;
    $url='http://'.$url unless $url=~/^http/i;
    $self->url($url);
}

# construct a mimetype based on a path
sub path2mimetype {
    my ($self,$path)=@_;
    $path||=$self->path;
    return undef unless $path;
    my $mt;
    my $suffix=suffix($path);
    if ($suffix) {
	$mt=MIME::Types->new->mimeTypeOf($suffix);
	$mt &&= $mt->simplified;
    } elsif (-d $path) {
	$mt='text/directory';
    }
    $mt;
}
########################################################################

# another constructor: create a object from a local path; may be obsolete
# also need url of this server, doc_root
sub from_path {
    my ($self,%argHash)=@_;
    my $path=$argHash{path} or confess "no path";
    $self->path($path);
    my $url=$self->set_url(%argHash);
    my $mt=$self->path2mimetype;
    $self->mimetype($mt) if $mt;

    my $owner=getpwuid((stat $path)[4])||$ENV{USER}||'nobody';
    return $self->new(url=>$url,
		      mimetype=>$mt,
		      owner=>$owner);
}


# extract the filename from the url:
sub filename {
    my ($self,%argHash)=@_;
    my $path=$self->path or return undef;
    my $doc_root=$ENV{DOCUMENT_ROOT}||$argHash{doc_root};
    $path=~s/$doc_root// if $doc_root;
    $path;
}

sub display_name { $_[0]->filename }

__PACKAGE__->_init_class;
1;
