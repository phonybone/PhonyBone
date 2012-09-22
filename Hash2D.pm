package PhonyBone::Hash2D;
use Moose;
use namespace::autoclean;

#has 'row_major' => (is=>'ro', isa=>'Int', default=>1);
# row_major==1 -> put(x,y) means row=x, col=y

has 'blank' => (is=>'ro', isa=>'Str', default=>''); # value to use for missing elements
has 'quote_elements' => (is=>'ro', isa=>'Int', default=>1);
has 'quote_chr' => (is=>'ro', isa=>'Str', default=>"'");


sub put { confess "Hash2D::put must be overridden" }
sub get { confess "Hash2D::get must be overridden" }

sub x_axis { confess "Hash2D::x_axis must be overridden" }
has 'x_delim' => (is=>'rw', isa=>'Str', default=>', ');

sub y_axis { confess "Hash2D::y_axis must be overridden" }
has 'y_delim' => (is=>'rw', isa=>'Str', default=>"\n");

sub as_str {
    my ($self, %opts)=@_;
    my @lines;

    # sort axis order; bad for big tables:
    my $xs=$self->x_axis;
    my $ys=$self->y_axis;

    $lines[0]=join($self->x_delim, $self->col0_header, @$xs) if $opts{include_headers};

    foreach my $y (@$ys) {
	my @line=();
	$line[0]=$y if $opts{include_headers};
	foreach my $x (@$xs) {
	    my $value=$self->get($x,$y) || $self->blank;
	    push @line, $value;
	}
	push @lines, join($self->x_delim, @line);
    }
    join ($self->y_delim, @lines);
}


sub quote_elem {
    my ($self, $elem)=@_;
    my $q=$self->quote_chr;
    $elem=~s/$q/\\$q/g;
    $q . $elem . $q;
}

sub n_rows { shift->y_next; }
sub n_cols { shift->x_next; }

__PACKAGE__->meta->make_immutable;

1;
