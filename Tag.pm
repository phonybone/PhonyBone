package PhonyBone::Tag;
use strict;
use warnings;
use Carp;
use Data::Dumper;

########################################################################
## Implements a tagging library.  
## Tags have a tag_id, tag_name, and (optionally) a tag_value.
## Multiple tagging is currently possible.
## Tags are not currently typed, although there is the beginnings or
## support for that; will require more creative database handling, but
## will allow for better sorting possiblilities.
## $Id: Tag.pm,v 1.14 2008/12/27 07:21:01 vcassen Exp $
########################################################################

# I'm really unsure that this needs to inherit from persistable, so leave as Relational
use base qw(PhonyBone::Relational);

use PhonyBone::FileUtilities qw(slurpFile spitString);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS %SYNONYMS);
@AUTO_ATTRIBUTES = qw(tag_id tag_name tag_value obj_class obj_eid);
@CLASS_ATTRIBUTES=qw(_tag2type _type_filename dbh_info
		     _dbh _tablename table_fields indexes uniques _tables primary_key
		     dbh_group);
		      
%DEFAULTS = 
    (
     table_fields=>{
	 tag_id=>'INT PRIMARY KEY AUTO_INCREMENT',
	 obj_eid=>'VARCHAR(255) NOT NULL',
	 obj_class=>'VARCHAR(255) NOT NULL',
	 tag_name=>'VARCHAR(255) NOT NULL',
	 tag_value=>'VARCHAR(255)'},

     _tablename=>'tag_string',
     _tables=>{tag_string=>'VARCHAR(255)', tag_int=>'INT', tag_float=>'FLOAT'},
#     uniques=>['obj_eid,tag_name,tag_value'],
     indexes=>[qw(tag_name tag_value obj_eid)],
     primary_key=>'tag_id',
     dbh_group=>'tags',
     );

%SYNONYMS = ();

Class::AutoClass::declare(__PACKAGE__);

use constant DEFAULT_TYPE=>'string';

sub _init_self {
    my ($self, $class, $args) = @_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this

    # check the name against the _tag2type hash
    # if no entry, and $args->{tag_type} is defined, add to %_tag2type
    # if there is an entry, make sure there is no attempt to redefine the tag type
    my $tag_name=$args->{tag_name} or confess "no tag_name";
    if (my $tag_type=$args->{tag_type}) {
	if (my $defined_type=$self->get_type) {
	    confess "types mismatch: '$tag_type' != '$defined_type'" unless
		$tag_type eq $defined_type;
	} else {		# assign type
	    $self->set_type($tag_name,$tag_type);
	}
    } else {			# no $args->{tag_type}, assign default
	$self->set_type($tag_name,DEFAULT_TYPE); # dumb; what if no name?
    }
}

sub _init_class {
    my ($class)=@_;
    $class->_read_tag_types;
}

# return the type of a tag or tag_name;
# that is, maps tag_name->type where type is one of keys %{$self->_tables}
# optional argument is a tag_name to lookup (overrides $self->tag_name)
# returns undef if not assigned
sub get_type {
    my $self=shift;
    my $tag_name=shift || (ref $self && $self->tag_name);
    return DEFAULT_TYPE unless $tag_name;
    my $tag2type=$self->tag2type;
    $tag2type->{$tag_name} || DEFAULT_TYPE;
}

# register a type in the tag2type hash:
sub set_type {
    my ($self,$name,$type)=@_;
    confess "no name" unless $name;
    confess "no type" unless $type;
#    if (!$type) {
#	$type=$name;
#	$name=$self->tag_name;
#    }
    my $tag2type=$self->tag2type;
    $tag2type->{$name}=$type;
}


# the %_tag2type hash keeps track of type of any named tag   
sub tag2type {
    my $self=shift;
    my $tag2type=$self->_tag2type || $self->_read_tag_types || {};
    $self->_tag2type($tag2type);
}

sub _read_tag_types {
    my $self=shift;
    my $filename=$self->_type_filename;
    return $self->_tag2type({}) unless ($filename && -r $filename);
    my $typemap=slurpFile($filename) or confess "Can't open '$filename': $!";
    $typemap=~/\$VAR1/ or die "typefile '$filename' has invalid format; should be output of Data::Dumper";
    my $VAR1;
    eval "$typemap"; die $@ if $@;
    die "contents of file '$filename' do not define a HASH ref" unless ref $VAR1 eq 'HASH';
    $self->_tag2type($VAR1);
}

# write %tag2type as Data::Dumper output
sub _write_tag_types {
    my $self=shift;
    my $filename=$self->_type_filename;
    my $typemap=$self->tag2type;
    spitString(Dumper($typemap),$filename) or die "Can't write to '$filename': $!";
    warn "$filename written\n" if $ENV{DEBUG};
}


# attach a tag to an object (stores to db)
sub attach {
    my ($self,$obj)=@_;

    $self->obj_eid($obj->primary_id);
    $self->obj_class(ref $obj);
    $self->store;
    return $self;
    
    # and we left this here why?
    my $obj_eid=$obj->primary_id or confess "no obj_eid in ",Dumper($obj);
    my $qobj_eid=$self->dbh->quote($obj_eid);
    my $qobj_class=$self->dbh->quote(ref $obj);
    my $qtag_name=$self->dbh->quote($self->tag_name);
    my $qtag_value=$self->dbh->quote($self->tag_value);
    my $tablename=$self->tablename;
    my $sql="INSERT INTO $tablename (tag_name,tag_value,obj_class,obj_eid) VALUES ($qtag_name,$qtag_value,$qobj_class,$qobj_eid)";
    $self->do_sql($sql);

    # grap tag_id:
    
    $self;
}

sub set_tablename {
    my ($self,$tablename)=@_;
    confess "no tablename" unless $tablename;
    $self->_tablename($tablename);
}

sub tablename {
    my $self=shift;
    return $self->_tablename unless ref $self;
    my $type=$self->get_type or confess "no type???";
    "tag_$type";
}

sub create_table {
    my ($self,%argHash)=@_;
    while (my ($tablename,$value_type)=each %{$self->_tables}) {
	$self->set_tablename($tablename);
	$self->table_fields->{tag_value}=$value_type;
	$self->SUPER::create_table(%argHash);
    }
}


# return all the objects tagged with this tag:
# actually returns a list[ref]; each element in the list
# is a two-element array containing obj_class and obj_id
sub object_ids {
    my ($self)=@_;
    confess "Tags::objects called as class method" unless ref $self;
    
    my $tablename=$self->tablename;
    my $where;
    if (my $tag_id=$self->tag_id) {
	$where="tag_id=".$self->tag_id;
    } else {
	$where="tag_name='".$self->tag_name."'";
	my $tag_value=$self->tag_value;
	if (defined $tag_value) {
	    my $qtag_value=$self->quote_value;
	    $where.=" AND tag_value=$qtag_value";
	}
    }
    my $sql="SELECT obj_class,obj_eid FROM $tablename WHERE $where";
    my $rows=$self->dbh->selectall_arrayref($sql);
    wantarray? @$rows:$rows;
}

# return all object_ids (as above) for a given tag name/value pair
# value may be undef, in which case any tag may match
# this needs to be renamed
sub search {
    my ($self,$tag_name,$tag_value)=@_;
    return $self->object_ids if ref $self;

    my $where="tag_name=".$self->dbh->quote($tag_name);
    $where.=" AND tag_value=".$self->dbh->quote($tag_value) if defined $tag_value;

    my @obj_eids;
    foreach my $tablename ($self->all_tablenames) {
	my $sql="SELECT obj_class,obj_eid FROM $tablename WHERE $where";
	push @obj_eids, @{$self->dbh->selectall_arrayref($sql)};
    }
    wantarray? @obj_eids:\@obj_eids;
}

sub quote_value {
    my $self=shift;
    my $tag_type=$self->get_type;
    return (!defined $tag_type || $tag_type eq 'string')? 
	$self->dbh->quote($self->tag_value) : 
	$self->tag_value;
}

sub all_tablenames { keys %{__PACKAGE__->_tables} }


# return the tags for an object:
sub tags {
    my ($self,$obj)=@_;
    
    my @tags;
    foreach my $tablename ($self->all_tablenames) {
	push @tags,$self->_get_tags($obj,$tablename);
    }
    wantarray? @tags:\@tags;
}

# return tags for an object as a hash[ref]: k=tag_name, v=tag_value
sub tag_hash {
    my ($self,$obj)=@_;
    my @tags=$self->tags($obj);
    my %hash=map {($_->tag_name,$_->tag_value)} @tags;
    wantarray? %hash:\%hash;
}

# get all tags for an object from a specific table
sub _get_tags {
    my ($self,$obj,$tablename)=@_;
    my $obj_eid=$obj->primary_id;
    my $qobj_class=$self->dbh->quote(ref $obj);
    my $qobj_eid=$self->dbh->quote($obj_eid);
    my $sql="SELECT tag_id,tag_name,tag_value FROM $tablename WHERE obj_eid=$qobj_eid AND obj_class=$qobj_class";
    my $rows=$self->dbh->selectall_arrayref($sql);
    my @tags=map {$self->new(tag_id=>$_->[0],tag_name=>$_->[1],tag_value=>$_->[2])} @$rows;
    wantarray? @tags:\@tags;
}

# test for tag name, tag type, and tag value (as appropriate)
sub equals {
    my ($self,$t2)=@_;
    confess "bad/missing self: $self" unless ref $t2 eq __PACKAGE__; # will break if Tag is subclassed
    confess "bad/missing t2: $t2" unless ref $t2 eq __PACKAGE__; # will break if Tag is subclassed
    return undef unless $self->tag_name eq $t2->tag_name;
    return undef unless $self->get_type eq $t2->get_type;
    return undef unless $self->tag_value eq $t2->tag_value;
    
    return 1;
}


sub store {
    my ($self,%argHash)=@_;
    if ($argHash{verify}) {	# make sure that obj_eid exists in db
	my $obj_class=$self->obj_class or confess "no object_class";
	confess "'$obj_class' does not use PhonyBone::Relational as a base class"
	    unless $obj_class->isa('PhonyBone::Relational');
	my $obj_eid=$self->obj_eid or confess "no object_eid";
	my $primary_key=$obj_class->primary_key;
	my $obj=$obj_class->new($primary_key=>$obj_eid)->fetch;
	confess "no such $obj_class w/id=$obj_eid" unless $obj;
    }
    $self->SUPER::store(%argHash);
}

sub delete_all {
    my ($self,%argHash)=@_;
    my $where=$argHash{where};
    foreach my $tablename (keys %{$self->_tables}) {
	my $sql="DELETE FROM $tablename";
	$sql.=" WHERE $where" if $where;
	$self->do_sql($sql);
    }
}

# delete all tags for an object:
# deletes from all type tables;
sub delete_obj {
    my ($self,$obj)=@_;
    my $qobj_class=$self->dbh->quote(ref $obj) or confess "'$obj' not an object";
    my $qobj_eid=$self->dbh->quote($obj->primary_id) or confess "no primary_id for ",Dumper $obj;
    foreach my $tablename (keys %{$self->_tables}) {
	my $sql="DELETE FROM $tablename WHERE obj_class=$qobj_class AND obj_eid=$qobj_eid";
	$self->do_sql($sql);
    }
}

__PACKAGE__->_init_class;
1;
