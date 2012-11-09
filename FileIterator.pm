package PhonyBone::FileIterator;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;
use FileHandle;
use PhonyBone::FileUtilities qw(dief);

has 'filename' => (is=>'ro', isa=>'Str', required=>1);
has 'fh' => (is=>'ro', isa=>'FileHandle', lazy=>1, builder=>'_build_fh');
sub _build_fh {
    my ($self)=@_;
    my $fh=new FileHandle($self->filename, 'r') or dief "Can't open %s: $!\n", $self->filename;
}

has 'no_chomp' => (is=>'ro', isa=>'Int', default=>0);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( filename => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};

sub BUILD {
    my ($self)=@_;
    $self->fh;			# force builder
}

sub has_next {
    my ($self)=@_;
    return !$self->fh->eof;
}

sub next {
    my ($self)=@_;
    my $fh=$self->fh;
    my $line=<$fh>;
    chomp $line if defined $line && ! $self->no_chomp;
    $line;
}

__PACKAGE__->meta->make_immutable;

1;
