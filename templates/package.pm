package PackageName;
use base qw(Exporter);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>\@EXPORT_OK);

sub new {
    my $proto=shift;
    my $class=ref $proto || $proto;
    my $self=bless {},$class;
    $self;
}

1;
