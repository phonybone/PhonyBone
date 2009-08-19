package PhonyBone::FileCollection;
use base qw(PhonyBone::Persistable);
use strict;
use warnings;
use Data::Dumper;
use Carp;

use DBI;
use PhonyBone::OrderedList;
use PhonyBone::Persistable::File;
use constant FILE_CLASS=>'PhonyBone::Persistable::File';

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw(collection_id collection_name files);
@CLASS_ATTRIBUTES=qw(dbh tablename primary_key indexes dbh_group);
%DEFAULTS = (
	     tablename=>'file_collection',
	     primary_key=>'collection_id',
	     indexes=>{collection_name=>'VARCHAR(255)'},
	     files=>PhonyBone::OrderedList->new,
	     dbh_group=>'persistable',
	     );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
    my $files=PhonyBone::OrderedList->new(ids_only=>1);
    $self->files($files);
}

sub _class_init {
    my ($class)=@_;
    $class->set_dbh;
}




########################################################################
# add a file to the end of the collection:
sub append_file {
    my ($self,$file)=@_;
    $file=FILE_CLASS->new(path=>$file) 
	unless (ref $file && $file->isa(FILE_CLASS));
    
    $self->files->add_end(id=>$file->primary_id);
}

# Add all the files in a directory
# argHash{directory}
# $argHash{recur}: set to true to recurse down subdirectories
# $argHash{filter}: regex to exclude files (default: qr(^\.|CVS);
sub add_directory {
    my ($self,%argHash)=@_;
    my $dir=$argHash{directory} or confess "no directory";
    my $filter=$argHash{filter} || qr(^\.|CVS);
    
    opendir(DIR,$dir) or die "Can't open directory $dir: $!\n";
    my @files=grep /$filter/, readdir DIR;
    closedir DIR;

    my @subdirs;
    foreach my $file (@files) {
	if (-d $file) {
	    push @subdirs,$file if $argHash{recur};
	} else {
	    $self->append_file($file);
	}
    }

    foreach my $subdir (@subdirs) {
	$self->add_directory(directory=>$subdir,
			     recur=>1, # implied by presence of items in @subdirs
			     filter=>$argHash{filter});
    }
    $self;
}

########################################################################


sub get_file {
    my ($self,$file_id,$mimetype)=@_;
    my $file;
    if ($self->files->ids_only) {
	my %args=(tag_file_id=>$file_id);
	$args{mimetype}=$mimetype if defined $mimetype;
	$file=FILE_CLASS->new_file(%args)->fetch;
    } else {
	$file=$self->files->item($file_id)->{item};
    }
    $file;
}

sub id_after    { shift->files->id_after(@_) }
sub item_after  { shift->files->item_after(@_) }
sub id_before   { shift->files->id_before(@_) }
sub item_before { shift->files->item_before(@_) }

sub first_id   { shift->files->first_id }
sub first_item { shift->files->first_item(@_) }
sub last_id    { shift->files->last_id }
sub last_item  { shift->files->last_item(@_) }

sub n_items { shift->files->n_items }

sub delete_file {
    my ($self,%argHash)=@_;
    my $file_id=$argHash{file_id} or confess "no file_id";
    $self->files->delete(id=>$file_id);
}

__PACKAGE__->_class_init();
1;


__END__
    my $db_name=$class->db_name or confess "no db_name for $class";
    my $dsn="DBI:mysql:host=localhost:database=$db_name";
    my $dbh=DBI->connect($dsn,'root','');
    $class->dbh($dbh);
    # todo: use Persistable::connect_dbh
