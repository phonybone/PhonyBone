package PhonyBone::Relational;
use strict;
use warnings;
use Carp;
use Data::Dumper;

########################################################################
# $Id: Relational.pm,v 1.19 2009/07/17 19:41:11 vcassen Exp $
# Class to model some database table functionality
########################################################################

use PhonyBone::DBHManager;
use DBI;


use Class::AutoClass;
use base qw(Class::AutoClass Exporter);
use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES @DEFAULTS @EXPORT_OK);

@EXPORT_OK=qw(@RELATIONAL_CLASS_ATTRS);
our @RELATIONAL_CLASS_ATTRS=qw(tablename table_fields indexes uniques no_sql_changes _dependent_classes _dbh db_info);
@CLASS_ATTRIBUTES=@RELATIONAL_CLASS_ATTRS;
@DEFAULTS = (tablename => '', table_fields => {}, indexes => [], uniques => [],
	     _dependent_classes=>[], db_info=>{});

Class::AutoClass::declare(__PACKAGE__);


sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}


# Class attrs that subclasses *must* implement should be defined as "confessionals"
# Might want an Abstract.pm class that defines abstract_method() as such
# Really would like to include it in Class::AutoClass (@ABSTRACT_METHODS)
# For now, all commented out as otherwise the methods are redefined
# Also look through sourceforge, perlmonks for other OO-implementing classes...


sub dbh_info {
    my $self=shift;
    return $self->db_info if $self->db_info;
    return PhonyBone::DBHManager->dbh_info($self);
}

sub db_name {
    my $self=shift;
    if (my $db_info=$self->db_info) {
	return $db_info->{db_name};
    }
    if (my $dbh_info=$self->dbh_info) {
	return $dbh_info->{db_name};
    }
    my $class=ref $self || $self;
    confess "no known db_name for $class";
}



sub dbh {
    my $self = shift;

    my $dbh=shift;		# might be undef
    $self->_dbh($dbh) if $dbh;
    return $self->_dbh if $self->_dbh;

    # $dbh not passed in, not yet assigned; use dbh_info to make connection:
    my $dbh_info=$self->dbh_info;
    $dbh_info=PhonyBone::Relational::dbh_info($self) unless $dbh_info;
    confess "no dbh info" unless $dbh_info;
    my $driver_type=$dbh_info->{engine} eq 'mysql'? 'database':'dbname';
    my $dsn="DBI:$dbh_info->{engine}:host=$dbh_info->{host};$driver_type=$dbh_info->{db_name}";
    warn "dsn is $dsn; dbh_info are ",Dumper($dbh_info) if $ENV{DEBUG};
    $dbh = DBI->connect($dsn, $dbh_info->{user}, $dbh_info->{password}, $dbh_info->{attr}) or 
	confess "$DBI::errstr";
    $self->_dbh($dbh);		# also returns $dbh
}


sub do_sql {
    my $self = shift;
    my $sql = shift or die "no sql";

    confess "no dbh" unless $self->dbh;
#    warn "$sql;\n" if $ENV{DEBUG};
    unless ($self->no_sql_changes) {
	if ($self->dbh->{RaiseError}) {
	    eval { $self->dbh->do($sql); };
	    confess "sql error: $@" if $@;	# promote death to confession
	} else {
	    $self->dbh->do($sql) or do {
		my $db_name=$self->db_name;
		$self->throw( $self->dbh->errstr."\nsql=$sql\n(db=$db_name)" );
	    };
	}
    }
}

sub create_table {
    my $self = shift;
    my %argHash = @_;

    my $class=ref $self || $self;
    my $tablename = $self->tablename or confess "no tablename for $class";
    my $table_fields = $self->table_fields or confess "no table_fields";

    $self->do_sql("DROP TABLE IF EXISTS $tablename") if ($argHash{drop_first});

    my $sql = "CREATE TABLE $tablename (";
    my @fields;
    foreach my $field (@{$self->fields}) {
	my $field_desc = $self->table_fields->{$field} or die "nothing known about field '$field'";
	push @fields, "$field $field_desc";
    }
    $sql .= join(', ', @fields) . ')';
    $self->do_sql($sql);

    my $indexes = $self->indexes || [];
    warn "indexes are ", join(', ', @$indexes), "\n" if $ENV{DEBUG};
    foreach my $index (@$indexes) {
	$self->do_sql("ALTER TABLE $tablename ADD INDEX ($index)");
    }

    my $uniques = $self->uniques || [];
    foreach my $index (@$uniques) {
	$self->do_sql("ALTER TABLE $tablename ADD UNIQUE ($index)");
    }
    warn "$tablename: shazam!\n" if $ENV{DEBUG};
}

sub table_exists {
    my $self=shift;
    my $tablename = $self->tablename or confess "no tablename";
    my $exists=0;

    eval {
	local $SIG{__WARN__} = sub {} unless $ENV{DEBUG};
	my $sql="SELECT COUNT(*) FROM $tablename";
	my $nrows=$self->do_sql($sql);
	$exists=1;
     };
    warn "error: $@" if $@ && $ENV{DEBUG};
    $exists;
}


# return the names of the fields (sorted alphabetically)
sub fields {
    my $self = shift;
    my $table_fields = $self->table_fields;
    my @fields = sort keys %$table_fields;
    wantarray? @fields : \@fields;
}


sub field_values {
    my $self = shift;
    my @values=map { $self->$_ } $self->fields;
    wantarray? @values : \@values;
}

# return a WHERE clause based on a Relational object.
# uses all fields of object with defined values.
# (does not include the keyword 'WHERE').
sub as_where {
    my $self=shift;
    my %hash=map {($_,$self->$_)} $self->fields;
    my @pairs;
    while (my ($k,$v)=each %hash) {
	push @pairs,"$k=".$self->dbh->quote($v) if defined $v;
    }
    return join(' AND ',@pairs);
}


# return the name of the primary key field
sub primary_key {
    my $self=shift;
    if ($self->can('_primary_key')) {
	my $pri_key=$self->_primary_key;
	return $pri_key if defined $pri_key;
    }
    # class of $self doesn't define _primary_key, look for it in %table_fields
    my $table_fields = $self->table_fields or confess "no table_fields";
    while (my ($field_name, $field_def) = each %$table_fields) {
	return $field_name if $field_def =~ /PRIMARY KEY/i;
    }
    return undef;
}

sub primary_id {
    my $primary_id=$_[0]->{$_[0]->primary_key}
}


sub field_needs_quotes {
    my ($self,$field)=@_;
    my $class=(ref $self) || $self;
    my $field_info=$self->table_fields->{$field} or 
	confess "$class: no field '$field' table for ",$self->tablename;
    $field_info=~/^VARCHAR|TEXT|DATE|ENUM/i;
}

########################################################################

# fetch via primary_key id
sub fetch {
    my $self = shift;
    my $class = ref $self or
	confess "Relational::fetch must be called on a reference";

    my $primary_key = $self->primary_key or confess "$class has no primary key";
    my $primary_value = $self->{$primary_key} or confess "no primary key value in class '$class'", Dumper($self),' ';
    my $qpv=$self->field_needs_quotes($primary_key)? $self->dbh->quote($primary_value):$primary_value;
    my $where = "$primary_key=$qpv";

    my $tablename=$self->tablename;
    my $fields=join(',',$self->fields);
    my $sql="SELECT $fields FROM $tablename WHERE $where";
    my @rows=$self->dbh->selectrow_array($sql); 
    return undef unless @rows;

    my %obj_args;
    foreach my $field ($self->fields) {
	my $value=shift @rows;
	$obj_args{$field}=$value;
    }
    return $class->new(%obj_args);
}

# return objects based on field/value pairs
sub fetch_where {
    my ($self,%argHash)=@_;
    my @fields=$self->fields;
    my @where;
    my $ops=$argHash{ops}||{};
    foreach my $field (@fields) {
	my $field_value=$argHash{$field} or next;
	$field_value=$self->dbh->quote($field_value) if $self->field_needs_quotes($field);
	my $op=$ops->{$field}||'=';
	push @where,"$field $op $field_value";
    }
    my $tablename=$self->tablename;
    my $field_names=join(',',@fields);
    my $where=join(' AND ',@where);
    my $sql="SELECT $field_names FROM $tablename WHERE $where";
    my $rows=$self->dbh->selectall_arrayref($sql);
    my $class=ref $self || $self;
    my @objs;
    foreach my $row (@$rows) {
	my %hash;
	@hash{@fields}=@$row;
	push @objs,$class->new(%hash);
    }
    wantarray? @objs:\@objs;
}

# takes a list of fieldnames and a hash of field/value pairs 
# list of fieldnames are fields selected
# field/values hash used to construct WHERE clause
# returns the results of selectall_arrayref as a list[ref]
sub select {
    my ($self,%argHash)=@_;
    my $dbh=$self->dbh or confess "no dbh";
    my $fields=$argHash{fields} || [];
    my $fieldnames=join(',',@$fields);
    my $values=$argHash{values} || {};
    my $where=join(' AND ',map {"$_=".$dbh->quote($values->{$_})} keys %$values);
    my $tablename=$self->tablename;
    my $sql="SELECT $fieldnames FROM $tablename";
    $sql.=" WHERE $where" if $where;
    my $rows=$dbh->selectall_arrayref($sql);
    wantarray? @$rows:$rows;
}

########################################################################

sub store {
    my $self=shift;
    my (@fields,@values);
    foreach my $field (@{$self->fields}) {
	my $value=$self->can($field)? $self->$field : $self->{$field};
	next unless defined $value;
	push @fields, $field;
	push @values, $value;
    }
    my $tablename=$self->tablename;
    my $fields=join(',',@fields);
    my $values=join(',',map {$self->dbh->quote($_)} @values);
    my $sql="INSERT INTO $tablename ($fields) VALUES ($values)";
    $self->do_sql($sql);

    # set primary_id:
    my $pri_id = $self->dbh->selectrow_array("SELECT LAST_INSERT_ID()");
    my $primary_key=$self->primary_key;
    $self->$primary_key($pri_id);
    $self;
}

########################################################################

# delete an object via primary_id:
sub delete {
    my $self=shift;
    my $primary_field=$self->primary_key or confess "no primary_key";
    my $pri_id=$self->{$primary_field} or confess ref $self,": no $primary_field in ", Dumper($self);
    my $qpri_id=$self->dbh->quote($pri_id);
    my $tablename=$self->tablename or confess "no tablename";
    my $sql="DELETE FROM $tablename WHERE $primary_field=$qpri_id";
    $self->dbh->do($sql);
    $self;
}

sub delete_all {
    my $self=shift;
    my $class=ref $self || $self;
    my $tablename=$self->tablename or confess "no tablename for $class";
    $self->do_sql("DELETE FROM $tablename");
}

########################################################################

# return a list(ref) of the names of any missing fields of an object:
sub missing_fields {
    my $self=shift;
    my %argHash=@_;
    confess "'$self' not a reference" unless ref $self;
    my $pri_key=$self->primary_key;
    my @missing;
    foreach my $f (@{$self->fields}) {
	next if ($f eq $pri_key && $argHash{skip_primary});
	push @missing,$f unless defined $self->$f;
    }
    wantarray?@missing:\@missing;
}

########################################################################

eval { require XML::Simple };
require "Relational.xml.pl" unless $@;

1;
