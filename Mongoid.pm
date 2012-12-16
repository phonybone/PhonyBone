package Mongoid;
use Moose::Role;

# 
# Role to provide functionality to MongoDB dbs.
#

use MongoDB;
use MooseX::ClassAttribute;
use PhonyBone::FileUtilities qw(warnf dief);
use Data::Dumper;
use Carp;
use Data::Structure::Util qw(unbless);

use parent qw(Exporter);
our @EXPORT_OK=qw(get_mongo ensure_indexes);

has '_id'    => (isa=>'MongoDB::OID', is=>'rw');	# mongo id

class_has 'db'         => (is=>'rw');
class_has 'connection' => (is=>'rw', isa=>'MongoDB::Connection');
class_has 'mongo_dbs'  => (is=>'rw', isa=>'HashRef', default=>sub {{}});

# Classes that use Mongoid must define these fields for themselves:
class_has 'host'            => (is=>'rw', isa=>'Str', default=>'local');
class_has 'db_name'         => (is=>'rw', isa=>'Str');	# classes override this on their own
class_has 'collection_name' => (is=>'rw', isa=>'Str'); # classes override this on their own
class_has 'primary_key' => (is=>'ro', isa=>'Str', default=>'_id');
sub mongo_coords {
    my $proto=shift;
    my $class=ref $proto || $proto;
    sprintf "%s:%s:%s", $class->host, $class->db_name, $class->collection_name;
}

# indexes example:
# class_has indexes => (is=>'rw', isa=>'ArrayRef', default=>sub{
#    [
#     {keys=>['name'], opts=>{unique=>1}},
#    ]}
#    );


sub BUILD {
    my $self=shift;
    return $self if $self->_id;	# db lookup alread done
    my $connection=eval {$self->connection};
    return unless (defined $connection);

    my $primary_key=$self->primary_key or return $self; # primary_key not set for some reason
    my $primary_id=$self->{$primary_key} or return $self;
    return $self unless defined $primary_id;
    warn "primary_id is $primary_id";
    $primary_id=int($primary_id) if $primary_id =~ /^-?\d+$/; # convert a digit string to an int

    my $class=ref $self;
    my $record=$self->get_record($primary_key => $primary_id);
    $self->hash_assign(%$record);
    $self;
}


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	if ($_[0]=~/^[a-f\d]{24}$/) {
	    my $oid=MongoDB::OID->new(value => $_[0]);
	    my $args=$class->get_record(_id=>$oid);
	    return $class->$orig(%$args);
	} elsif ($class->can('primary_key')) {
	    return $class->$orig( $class->primary_key => $_[0] );
	} else {
	    dief "Bad arg to single-arg constructor for %s: %s",
	    $class, $_[0];
	}
    } else {
	return $class->$orig(@_);
    }
};


# return the mongo db (ie, collection) for this class:
# to get a collection, we need a mongodb connection and a mongodb database.
# also calls ensure_index as necessary
# cache by class
sub mongo {
    my ($self)=@_;
    my $class=ref $self || $self;
    if (my $mongo=$self->mongo_dbs->{$class}) { 
	return $mongo; 
    }
    confess "no db_name for $class" unless $class->db_name;

    if (! defined $class->db) {
	
        # connect if haven't already done so (warning: can die)
	my $host=$self->host;
	my %connect_args;
	$connect_args{host}=$host unless $host eq 'local';
	$self->connection(MongoDB::Connection->new(%connect_args)) unless $self->connection; 

	my $db_name=$class->db_name;
	$class->db($self->connection->$db_name); # get db
    }

    my $collection_name=$class->collection_name or confess "no collection_name for '$class'";
    my $collection=$class->db->$collection_name;
    $self->mongo_dbs->{$class}=$collection;
    $collection->{slave_ok}=1;

    # ensure indexes:
    if (my $pk=$class->primary_key) {
	$collection->ensure_index({$pk=>1}, {unique=>1});
    }
    if ($class->can('indexes')) { # see AutoRecon::Reaction for example
	ensure_indexes($class, $class->indexes);
    }

    $collection;
}

sub ensure_indexes {
    my ($class, $indexes)=@_;
    $indexes||=$class->indexes;
    my $collection=$class->mongo;
    foreach my $index_hash (@$indexes) {
	die "bad index_hash", Dumper($index_hash) if 
	    ref $index_hash ne 'HASH' ||
	    ! $index_hash->{keys} ||
	    ref $index_hash->{keys} ne 'ARRAY';
	my $keylist=$index_hash->{keys} or confess "no keys";
	my %keys=map {($_,1)} @$keylist;
	my $opts=$index_hash->{opts} or confess " no opts";
	$collection->ensure_index(\%keys, $opts);
	warn "indexed $class using ", Dumper(\%keys), "opts: ", Dumper($opts) if $ENV{DEBUG};
    }
}

sub get_mongo {
    my ($db_name, $collection_name)=@_;

    use Carp qw(cluck);
    cluck sprintf "looking for connection for class '%s'", __PACKAGE__;
    my $connection=__PACKAGE__->connection;
    unless ($connection) {    
	$connection=MongoDB::Connection->new;
	__PACKAGE__->connection($connection) ; # connect if haven't already done so
    }
    
    $connection->$db_name->$collection_name; # should create everything as needed
}

########################################################################

sub get_record {
    my ($self, $primary_key, $primary_id)=@_;
    my $query={$primary_key=>$primary_id};
    $self->mongo->find_one($query);
}

# Find and return an array[ref] of objects (calls constructor for every record)
sub find {
    my ($class, $query, $opts)=@_;
    $class = ref $class || $class; # get class if object supplied
    $query ||= {};
    $opts ||= {};
    my $cursor=$class->mongo->find($query, $opts);
    my @objs=map {new $class(%$_)} $cursor->all;
    wantarray? @objs:\@objs;
}

# find one record via $oid: ($oid should be $self->_id->{value})
sub find_one {
    my ($self, $_id)=@_;
    my $oid=new MongoDB::OID(value=>$_id);
    my $cursor=$self->mongo->find({_id=>$oid});
    dief "No record for _id=$_id in %s", $self->mongo_coords 
	unless $cursor && $cursor->has_next;
    my $record=$cursor->next;
    my $class=ref $self||$self;
    $class->new(%$record);
}

# return the ts of the record extracted from the oid:
# return undef if unable to extract a ts
sub oid_ts {
    my ($self)=@_;
    my $oid=$self->_id or return undef;
    $oid->get_time;
}

sub save {
    my ($self, $options)=@_;
    $options||={};
    my $rc=$self->mongo->save($self, $options);
    $self->_id($rc) if ref $rc eq 'MongoDB::OID';
    $self;
}
sub insert { save(@_) }

# Update records in the objects/classes mongo table
# Not generally applicable for single objects; use 'save' for that
sub update {
    my ($self, $query, $updates, $opts)=@_;
    confess "bad/missing query" unless ref $query eq 'HASH';
    unless (%$query) {
	confess "'$self': not a ref or can't call '_id'" unless ref $self && $self->can('_id');
	$query={_id=>$self->_id}; 
    }
    confess "bad/missing updates" unless ref $updates eq 'HASH';
    $opts||={}; $opts->{safe}=1;
    $self->mongo->update($query, $updates, $opts);
}

# Delete self, via _id:
sub delete {
    my ($self)=@_;
    $self->mongo->remove({_id=>$self->_id});
    $self;
}    

sub delete_all {
    my ($self)=@_;
    $self->mongo->remove();
    $self;
}

# remove all the dups of a record
# NOT threadsafe; works by removing all instances of record, the re-inserting
# Also changes _id, which might be bad; should be used only with classes that don't care
sub remove_dups {
    my ($self, $options)=@_;
    my $collection=$self->mongo;
    
    # Can't use blessed refs in mongo->remove, I think:
    my $class=ref $self;
    unbless $self;		# arrgghh!  It burns!
    delete $self->{_id};	# It's ripping my soul away!

    $collection->remove($self, $options); # removes all matching
    $collection->insert($self); # put one copy back in
    bless $self, $class;	# ahhhh...
}


# Assign the contents of a hash to a Mongoid object.  Extract each 
# field of hash for which a geo accessor exists.
# overwrites existing key/values, except for keys starting 
# with '_', but will overwrite '_id'.
# Returns $self
sub hash_assign {
    my ($self, @args)=@_;
    confess "ref found where list needed" if ref $args[0]; # should be a hash key
    my %hash=@args;
    while (my ($k,$v)=each %hash) {
	$self->{$k}=$v unless $k=~/^_/;
    }
    $self->_id($hash{_id}) if $hash{_id}; # as in constructor
    $self;
}

sub record {
    my ($self)=@_;
    my %record=%$self;
#    unbless \%record;
    
    wantarray? %record:\%record;
}




1;

__END__

    # Check for a running mongod instance.  We may need to move this away from
    # compile-time code...
    eval {GEO::Series->mongo};
    if ($@) {
	$@=~s| at /.*||ms;
	die "Unable to connect to mongo db.  Verify mongod is running (err=$@)\n\n";
    }

