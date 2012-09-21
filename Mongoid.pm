package Mongoid;

# 
# "Mixin" class to provide functionality to MongoDB dbs.
#


use Moose::Role;
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
class_has 'db_name'         => (is=>'ro', isa=>'Str');	# classes override this on their own
class_has 'collection_name' => (is=>'ro', isa=>'Str'); # classes override this on their own
class_has 'primary_key' => (is=>'ro', isa=>'Str', default=>'_id');

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
    my $primary_id=$self->{$primary_key};
    return $self unless defined $primary_id;
    $primary_id=int($primary_id) if $primary_id =~ /^-?\d+$/;

    my $class=ref $self;
    my $record=$self->get_record($primary_key => $primary_id);
    $self->hash_assign(%$record);
    $self;
}


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] && $class->can('primary_key')) {
	return $class->$orig( $class->primary_key => $_[0] );
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
    if (my $mongo=$self->mongo_dbs->{$class}) { return $mongo; }
    confess "no db_name for $class" unless $class->db_name;

    if (! defined $class->db) {
	use Carp qw(cluck);
        # connect if haven't already done so (warning: can die)
	$self->connection(MongoDB::Connection->new) unless $self->connection; 

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
    my $collection=$class->mongo;
    foreach my $index_hash (@$indexes) {
	die "$index_hash: bad index_hash" if 
	    ref $index_hash ne 'HASH' ||
	    ! $index_hash->{keys} ||
	    ref $index_hash->{keys} ne 'ARRAY';
	my $keylist=$index_hash->{keys} or confess "no keys";
	my %keys;
	@keys{@$keylist}=@$keylist;
	my $opts=$index_hash->{opts} or confess " no opts";
	$collection->ensure_index(\%keys, $opts);
    }
}

sub get_mongo {
    my ($db_name, $collection_name)=@_;

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

sub find {
    my ($class, $query, $opts)=@_;
    $class = ref $class || $class; # get class if object supplied
    $query ||= {};
    $opts ||= {};
    my $cursor=$class->mongo->find($query, $opts);
    my @objs=map {new $class(%$_)} $cursor->all;
    wantarray? @objs:\@objs;
}

sub find_one {
    my ($self, $id)=@_;
    $id ||= $self->primary_key or confess "no primary key";
    confess "nyi";
}

sub save {
    my ($self, $options)=@_;
    my $rc=$self->mongo->save($self, $options);
    $self->_id($rc) if ref $rc eq 'MongoDB::OID';
    $self;
}
sub insert { save(@_) }

# update a record, using _id.
# Omits keys starting with '_'
# $opts is a hashref; accepted keys are 'upsert', 'multiple'.
sub update {
    my ($self, $opts)=@_;
    my $record={};
    while (my ($k,$v)=each %$self) { # copy fields to new record, ...
	$record->{$k}=$v unless $k=~/^_/; # ...skipping "_keys"
    }
    $opts||={}; $opts->{safe}=1;
    my $geo_id=$self->geo_id;
    my $report=$self->mongo->update({geo_id=>$geo_id}, $record, $opts);
    warn "update $geo_id: nothing updated (_id not set, nor upsert)\n" if $report->{n}==0;
#    warn "update: ",Dumper($report);
    my $_id=$report->{upserted};
    $self->_id($_id) if ref $_id eq 'MongoDB::OID'; # only works because geo_id is like a primary key
    $self;
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


# Assign the contents of a hash to a geo object.  Extract each field of hash for which
# a geo accessor exists.
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
