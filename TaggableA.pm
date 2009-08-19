package PhonyBone::TaggableA;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use PhonyBone::Tag;

########################################################################
# Name:        .
# Version:     $Id: TaggableA.pm,v 1.13 2008/09/02 16:09:11 vcassen Exp $
# Author:      .
# Date:        .
# Description: Represents some object that can have tags associated with it.
# Class variables:
# -type: a single word type to id the class to the tagserver.
########################################################################


#use base qw(PhonyBone::Relational);
#use base qw(PhonyBone::Persistable);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS %SYNONYMS $tag_class);
@AUTO_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(type type2class);
%DEFAULTS = (type2class=>{});
%SYNONYMS = ();
$tag_class='PhonyBone::Tag';

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my ($self, $class, $args) = @_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

sub _init_class {
    my ($self)=@_;
    $self->register_type;
}

# abstract
sub obj_id {
    my $proto=shift;
    my $class=ref $proto || $proto;
    confess "class '$class' must implement method 'obj_id'";
}


# tag this object with a tag (calls Tag::attach, which stores to db):
sub tag {
    my ($self,@args)=@_;
    my $tag;
    if (@args==1 && ref $args[0] && $args[0]->isa($tag_class)) {
	$tag=$args[0];
    } elsif (@args==1 && ref $args[0] eq 'HASH') {
	$tag=$tag_class->new(%{$args[0]});
    } elsif (@args==2) {
	if ($args[0] eq 'tag_name') {
	    $tag=$tag_class->new(@args); 
	} else {
	    $tag=$tag_class->new(tag_name=>$args[0],tag_value=>$args[1]);
	}
    } else {
	$tag=$tag_class->new(@args); # let Tag class sort it out (or try to)
    }

    $tag->attach($self);	# back atchya, should return tag
}

# return the tag objects for this object
sub tags {
    my ($self)=@_;
    return $tag_class->tags($self);
}

# abstracts
sub url {
    my $proto=shift;
    my $class=ref $proto || $proto;
    confess "class '$class' must implement method 'url'";
}

sub display_name {
    my $proto=shift;
    my $class=ref $proto || $proto;
    confess "class '$class' must implement method 'display_name'";
}

# delete all the tags for an object as well as the object itself
sub delete {
    my $self=shift;
    $tag_class->delete_obj($self);
    $self->SUPER::delete;
}

sub register_type {
    my ($self)=@_;
    my $class=ref $self || $self;
    my $type=$self->type or confess "no type for $class";
#    warn "$class: type->$type";
    $self->type2class->{$type}=$class;
}


1;
