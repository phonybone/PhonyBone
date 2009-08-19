package PhonyBone::Persistable;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use PhonyBone::ListUtilities qw(soft_copy);
use PhonyBone::DBHManager qw(get_dbh);

########################################################################
# An attempt at database-based persistance for AutoClass objects.
# We're not using AutoDB simply because we neither understand nor trust
# it, but maybe in the future...
#
# How to inherit from this class:
# define class methods for indexes, tablename, primary_key, and db_name
# define instance methods for any variables needed as indexes
#
# TODO:
# 1. Test with more inheritance; if File->isa(Persistable), and 
#    Image->isa(File), but with more Autoclass fields, does this all
#    work ok?
# 2. Do a real version of update;
# 3. Settle the thing about allowing to store objects that already have ids
#    (maybe they should be skipped in the store routine...?)
# 4. Allow db_name to change depending on machine (might farm that out to
#    to dbhandler and inheriting classes).
########################################################################

use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES=qw(dbh_group);
%DEFAULTS = (
	     dbh_group=>'persistable',
	     );

# abstract methods: must be implemented by inheriting classes:
sub indexes     { confess "$_[0] does not implement method 'indexes'" }
#sub db_name     { confess "$_[0] does not implement method 'db_name'" }
#sub db_name { $_[0]->dbh_info->{db_name}}
sub tablename   { confess "$_[0] does not implement method 'tablename'" }
sub dbh         { confess "$_[0] does not implement method 'dbh'" }
sub primary_key { confess "$_[0] does not implement method 'primary_key'" }

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}


sub set_dbh {
    my ($class)=@_;
    my $dbh=PhonyBone::DBHManager->get_dbh($class);
    $class->dbh($dbh);
}


# still needs work; db_name could be different depending on machine...
sub connect_dbh_old {
    my ($class)=@_;
    my $db_name=$class->db_name or confess "no db_name for $class";
    my $dsn="DBI:mysql:host=localhost:database=$db_name";
    my $dbh=DBI->connect($dsn,'root','');
    $class->dbh($dbh);
}

sub db_name { PhonyBone::DBHManager->db_name($_[0]) }
sub primary_id { $_[0]->{$_[0]->primary_key} }

sub create_table {
    my ($self,%argHash)=@_;
    my $tablename=$self->tablename;
    my $dbh=$self->dbh;

    $dbh->do("DROP TABLE IF EXISTS $tablename") if $argHash{drop_first};

    my $primary_key=$self->primary_key or confess "no primary_key";
    # assumed to be int for now...
    my $sql="CREATE TABLE $tablename ";
    $sql.="($primary_key INT PRIMARY KEY AUTO_INCREMENT, ";
    $sql.="object LONGTEXT NOT NULL";

    my $indexes=$self->indexes;
    while (my ($field_name,$type)=each %$indexes) {
	$sql.=", $field_name $type";
    }
    $sql.=")";

    $dbh->do($sql) or confess $dbh->errstr;

    # Also want to create indicies:
    foreach my $index (keys %$indexes) {
	my $sql="ALTER TABLE $tablename ADD INDEX ($index)";
	$dbh->do($sql) or confess $dbh->errstr;;
    }
    warn $self->db_name,":$tablename: shazam!\n";
}


sub store {
    my ($self,%argHash)=@_;
    my $tablename=$self->tablename or confess "no tablename";
    my $dbh=$self->dbh or confess "no dbh";

    # TODO: allow for insertion when $self->primary_id is already
    # defined.  Wait, why?  So that update() can retain the same id,
    # when update()={delete(),store()}

    # copy all the persistable sub-objects from $self into a hash;
    # replace their entry with a code snippet that will re-create them,
    # then call store() on the sub-objects.
    # TODO: create an iterator class and use that instead of separate loops.
    # That way hashes and arrays can be treated the same
    my %pers;
    if ($self=~/HASH/) {
	while (my ($k,$v)=each %$self) {
	    next unless (ref $v) && ($v->isa('Persistable'));
	    $pers{$k}=$v;	# store persistable sub-object for later
	    my $subclass=ref $v;
	    my $pri_key=$subclass->primary_key;	# just let this fail? or trap?
	    my $pri_id=$v->primary_id;
	    $pri_id='%%' unless defined $pri_id; # have to replace after $v is stored
	    my $stm="require $subclass; $subclass->new($pri_key=>$pri_id)->fetch"; # /^require / serves as flag to fetch (or not)
	    $self->{$k}=$stm;
	}
#    } elsif (ref $self eq 'ARRAY') {
    } else {
	confess "Don't know how to store non-hash persistable objects";
    }

    # store sub objects in %pers:
    unless ($argHash{something}) { # TODO: come up with a better name for arg ;/
	foreach my $o (values %pers) { $o->store if $o->primary_id eq '%%'; }; # could also try to fetch object...?
	# if $o->primary_id ne '%%' then the object was already stored some other time
    }

    # replace '%%' with primary ids of sub-object fetch code as necessary, now that they've been stored (which sets $o->primary_id):
    while (my ($k,$v)=each %$self) {
	next unless $v=~/%%/;	# this could barf for printf-type formatting strings....
	my $o=$pers{$k} or confess "no pers{$k}???";
	my $pri_id=$o->primary_id or confess "no primary_id in ",Dumper($o),'???';
	$v=~s/%%/$pri_id/;	# recall $v is the code snippet to restore a sub-object
	$self->{$k}=$v;
    }

    # create the freeze image:
    my $freeze=Dumper($self);
    $freeze=~s/\s+/ /gms;	# condense whitespace
    my $f_len=length $freeze;	# used in debugging, nowhere else

    # create VALUES portion of INSERT statement; include all defined indexes
    my (@fieldnames,@values);
#    local $SIG{__DIE__}=sub {confess @_};
    foreach my $index (keys %{$self->indexes}) {
	my $value=$self->$index;
	next unless defined $value;
	push @fieldnames,$index;
	push @values,$dbh->quote($value)
    }

    # add in 'object' and $freeze to sql and finish creating VALUES:
    push @fieldnames,'object';
    my $fieldnames=join(',',@fieldnames);
    push @values,"\"$freeze\"";
    my $values=join(',',@values);
    
    # assemble and execute INSERT sql:
    my $sql="INSERT INTO $tablename ($fieldnames) VALUES ($values)";
    warn "$sql;" if $argHash{debug};
    $dbh->do($sql) or confess $dbh->errstr;

    # find out primary_id and add to object:
    my $pri_id=$self->dbh->selectrow_array("SELECT LAST_INSERT_ID()");
    my $primary_key=$self->primary_key;
    $self->$primary_key($pri_id);
    $self;
}

# fetch objects based on a partially populated object or %argHash
# Can't do LIKE, NOT, etc.
sub fetch {
    my ($self,%argHash)=@_;
    my $class=ref $self || $self;
    my $dbh=$class->dbh or confess "no dbh";
    my $tablename=$class->tablename or confess "no tablename";

    if ($argHash{debug}) {
	warn "self is ",Dumper($self);
	warn "argHash is ",Dumper(\%argHash);
    }

    # start constructing SQL:
    my $primary_key=$class->primary_key or confess "no primary_key";
    my $sql="SELECT $primary_key,object FROM $tablename WHERE ";
    my $primary_id=($self->$primary_key || $self->primary_id) if ref $self;
    $primary_id ||=($argHash{$primary_key}||$argHash{primary_key});
    $sql.="$primary_key='$primary_id'" if defined $primary_id;

    # add in indexes to SQL (in WHERE)
    my @stuff;
    local $SIG{__DIE__}=sub {confess @_};
    my $indexes=$class->indexes;

    foreach my $index (keys %{$class->indexes}) {
	my $value=ref $self? $self->$index : $argHash{$index};
	next unless defined $value;
	my $qindex=$dbh->quote($value);
	push @stuff, "$index=$qindex";
#	$sql.=" AND $index='".$self->$index."'" if defined $self->$index;
    }
    $sql.=join(' AND ',@stuff) if @stuff;
    warn "$sql;" if $argHash{debug};

    # issue SQL call, eval result and assign to $obj
    my $rows=$dbh->selectrow_arrayref($sql);
    my $thaw;
    eval '$thaw=$rows->[1]';	# eval in case nothing found
    return undef unless $thaw;
    my $VAR1;
    eval "$thaw";
    my $obj=$VAR1;

    # set primary_id:
    $obj->$primary_key($rows->[0]) unless defined $obj->$primary_key;

    # for any items that are strings containing evals, eval the code:
    # TODO: change to iterator:
    while (my ($k,$v)=each %$obj) {
	next unless $v=~/^require/; # sure hope that's unique enough....
	my $v2=eval $v; die "'$v': $@" if $@;
	$obj->{$k}=$v2 if defined $v2;
    }
    $obj;
}


# delete from the db
# do we delete sub-objects? Hard to be sure that $self is the only containing
# object with a reference to sub objects (unless we implement some form of reference
# counting; ugh).  So for now, no.
sub delete {
    my ($self, %argHash)=@_;
    soft_copy($self,\%argHash);

    my @where;
    my $primary_key=$self->primary_key or confess "no primary_key for ",(ref $self || $self);
    if (my $pri_id=$self->$primary_key) {
	my $qpri_id=$self->dbh->quote($pri_id);
	push @where,"$primary_key=$qpri_id";
    }

    # we can also delete by index values
    foreach my $f (keys %{$self->indexes}) {
	next if $f eq $primary_key; # play it safe
	my $v=$self->{$f};
	next unless defined $v;
	my $qv=$self->dbh->quote($v);
	push @where,"$f=$qv";
    }
    confess "nothing in WHERE clause" unless @where;
    my $where=join(' AND ',@where);

    my $tablename=$self->tablename;
    my $sql="DELETE FROM $tablename WHERE $where";
    $self->dbh->do($sql);
    $self->$primary_key(undef);
    $self;
}

sub update {
    my ($self)=@_;
    my $pid=$self->primary_id;
    $self->delete;
    $self->store;		# this won't work; store() is a "deep" copy, delete isn't
}


1;

__END__
sub store_old {
    my ($self)=@_;

    my $tablename=$self->tablename or confess "no tablename";
    my $dbh=$self->dbh or confess "no dbh";
    my $freeze=Dumper($self);
    $freeze=~s/\s+/ /gms;	# condense whitespace
    my $f_len=length $freeze;	# used in debugging, nowhere else

    my (@fieldnames,@values);
    foreach my $index (keys %{$self->indexes}) {
	my $value=$self->$index;
	next unless defined $value;
	push @fieldnames,$index;
	push @values,$dbh->quote($value)
    }
    push @fieldnames,'object';
    my $fieldnames=join(',',@fieldnames);
    push @values,"\"$freeze\"";
    my $values=join(',',@values);
    
    my $sql="INSERT INTO $tablename ($fieldnames) VALUES ($values)";
    $dbh->do($sql) or confess $dbh->errstr;

    my $pri_id=$self->dbh->selectrow_array("SELECT LAST_INSERT_ID()");
    my $primary_key=$self->primary_key;
    $self->$primary_key($pri_id);
}

sub fetch_old {
    my ($self,%argHash)=@_;
    my $class=ref $self || $self;
    my $dbh=$class->dbh or confess "no dbh";
    my $tablename=$class->tablename or confess "no tablename";

    my $primary_key=$class->primary_key or confess "no primary_key";
    my $sql="SELECT $primary_key,object FROM $tablename WHERE ";
    my $primary_id=ref $self? $self->$primary_key : $argHash{$primary_key};
    $sql.="$primary_key='$primary_id'" if defined $primary_id;

    my @stuff;
    foreach my $index (keys %{$class->indexes}) {
	my $value=ref $self? $self->$index : $argHash{$index};
	next unless defined $value;
	my $qindex=$dbh->quote($value);
	push @stuff, "$index=$qindex";
#	$sql.=" AND $index='".$self->$index."'" if defined $self->$index;
    }
    $sql.=join(' AND ',@stuff) if @stuff;

    my $rows=$dbh->selectrow_arrayref($sql);
    my $thaw;
    eval '$thaw=$rows->[1]';	# eval in case nothingn found
    return undef unless $thaw;
    my $VAR1;
    eval "$thaw";
    my $obj=$VAR1;
    $obj->$primary_key($rows->[0]) unless defined $obj->$primary_key;
    $obj;
}
