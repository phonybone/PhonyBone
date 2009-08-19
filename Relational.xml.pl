package PhonyBone::Relational;

use XML::Simple;
our $xml_parser=XML::Simple->new;


sub xml {
    my ($self)=@_;
    confess __PACKAGE__,"::xml() called as class method" unless ref $self;
    $xml_parser->XMLout($self,KeyAttr=>[]);
}

sub read_xml {
    my ($self,$xml)=@_;
    my $primary_key=$self->primary_key;
    my $hash=$xml_parser->XMLin($xml,ForceArray=>1,KeyAttr=>[$primary_key]);
    my $class=ref $self || $self;
    my $obj=$class->new(%$hash);
    $obj;
}

# convert an xml string contain multiple objects to a list[ref] of objects:
sub read_xml_list {
    my ($self,$xml)=@_;
    my $class=ref $self || $self;
    my $primary_key=$self->primary_key;
    my $opt_list=$xml_parser->XMLin($xml,KeyAttr=>[$primary_key])->{opt};
    my @objs;
    foreach my $h (@$opt_list) {
	confess "'$h' not a hash ref" unless ref $h eq 'HASH';
	push @objs,$class->new(%$h);
    }
    wantarray? @objs:\@objs;
}

1;
