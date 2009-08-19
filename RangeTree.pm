package PhonyBone::RangeTree;
use base qw(Class::AutoClass);
use strict;
use warnings;
use Carp;
use Data::Dumper;

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS @EXPORT_OK);
@AUTO_ATTRIBUTES = qw(root size depth);
@CLASS_ATTRIBUTES=qw();
%DEFAULTS = (
	     );
@EXPORT_OK=qw(find_node);

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
    $self->size(0);
    $self->depth(0);
}

sub efficiency { $_[0]->size/(($_[0]->depth**2)-1) }

# return a simple hashref w/keys lo, hi, obj, left, right
# initializes lo, hi, obj; left, right left as undef
sub new_node {
    my ($lo,$hi,$obj)=@_;
    confess "missing args" unless $hi && $lo && $obj;
    confess "'$hi' < '$lo'" if $hi < $lo; # sticking w/integers for now
    {hi=>$hi,lo=>$lo,obj=>$obj,left=>undef,right=>undef};
}

# insert a new node containing the data; returns the new size of the tree
sub insert {
    my ($self,$lo,$hi,$obj)=@_;
    my $n=new_node($lo,$hi,$obj);
    if (!$self->root) {
	$self->root($n);
	$self->depth(1);
	return 1;
    }
    my $depth=insert_node($self->root,$n,1);
    $self->depth($depth) if $depth>$self->depth;
    $self->size($self->size+1);
}

# insert a node into the tree
# return the depth of the inserted node
# throws a string exception of the node to be inserted overlaps
# with another node.  String contains a dump of the object, a dump of the 
# existing node, and the offending ranges.
sub insert_node {
    my ($root,$nd,$depth)=@_;
    if (overlaps($root,$nd)) {
	die sprintf "%s (%s-%s) overlaps %s (%s-%s)",
	Dumper($root->{obj}), $root->{lo}, $root->{hi},
	Dumper($nd->{obj}), $nd->{lo}, $nd->{hi};
    }

    if ($root->{lo} > $nd->{hi}) {
	if ($root->{left}) {	# insert on "lower" branch
	    $depth=insert_node($root->{left},$nd,$depth+1);
	} else {
	    $root->{left}=$nd;
	    return $depth+1;
	}
    } else {			# insert on "higher" branch
	if ($root->{right}) {
	    $depth=insert_node($root->{right},$nd,$depth+1);
	} else {
	    $root->{right}=$nd;
	    return $depth+1;
	}
    }
    return $depth;
}


sub overlaps {
    my ($s,$n)=@_;
    if    ($s->{lo} >= $n->{lo}) { return $s->{lo} <= $n->{hi} }
    elsif ($s->{hi} <= $n->{hi}) { return $s->{hi} >= $n->{lo} }
    else                        { return 1 }
}

sub node_contains {
    my ($n,$i)=@_;
    return ($n->{lo}<=$i) && ($n->{hi}>=$i);
}

# return the object within the specified range
# (or undef)
sub find {
    my ($self,$i)=@_;
    confess "no i" unless defined $i;
    my $n=find_node($self->root,$i) or return undef;
    $n->{obj};
}


# return the node containing a value (or undef if no such node)
sub find_node {
    my ($root,$i)=@_;
    confess "no i" unless defined $i;
#    confess "weird node: ",Dumper($root);
    unless ($root->{lo} && $root->{hi}) {
	confess "weird node: ",node_string($root);
    }
    return $root if $root->{lo}<=$i && $root->{hi}>=$i;
    if ($root->{lo}>$i) {
	my $left=$root->{left} or return undef;
	find_node($left,$i);
    } elsif ($root->{hi}<$i) {
	my $right=$root->{right} or return undef;
	find_node($right,$i);
    }
}

########################################################################
# left,node,right
sub infix_traversal {
    my ($root,$subref,$depth)=@_;
    $depth||=0;
    infix_traversal($root->{left},$subref,$depth+1) if $root->{left};
    $subref->($root,$depth);
    infix_traversal($root->{right},$subref,$depth+1) if $root->{right};
}

# node,left,right
sub prefix_traversal {
    my ($root,$subref,$depth)=@_;
    $depth||=0;
    $subref->($root,$depth);
    prefix_traversal($root->{left},$subref,$depth+1) if $root->{left};
    prefix_traversal($root->{right},$subref,$depth+1) if $root->{right};
}

# left,right,node
sub postfix_traversal {
    my ($root,$subref,$depth)=@_;
    $depth||=0;
    postfix_traversal($root->{left},$subref,$depth+1) if $root->{left};
    postfix_traversal($root->{right},$subref,$depth+1) if $root->{right};
    $subref->($root,$depth);
}



# verify that all nodes are properly ordered and that no nodes overlap
# returns a list[ref] of nodes that overlap, or undef if none overlap.
# list element is two-element array: [node_string($o),node_string($p)]
sub _sanity_check {
    my ($self)=@_;
    my @objs;
    # gather all nodes in a list:
    infix_traversal($self->root,sub { push @objs,$_[0] });

    my @overlapping;
    my $p=shift @objs or return wantarray? ():undef;
    foreach my $o (@objs) {
	push(@overlapping, [node_string($o),node_string($p)]) if $o->{lo}<$p->{hi};
	$p=$o;
    }

    return wantarray? ():undef unless @overlapping;
    wantarray? @overlapping:\@overlapping;
}

sub as_string {
    my ($self,$j,$print_sub)=@_;
    $j=' ' unless defined $j;
    my @str;
    infix_traversal($self->root, sub {
	my $o=$_[0]->{obj};
	my $name=ref $o? ($print_sub? $o->$print_sub():Dumper($o)) : $o;
	push @str,sprintf("%s->%s: $name (%d)", $_[0]->{lo},$_[0]->{hi}, $_[1]);
    });
    join($j,@str);
}

sub as_indented_string {
    my ($self)=@_;
    my $str;
    infix_traversal($self->root, sub {
	$str.='.' x $_[1];
	$str.=sprintf("%s - %s\n",$_[0]->{lo},$_[0]->{hi});
    });
    $str;
}

# print a node's info, omitting left and right
sub node_string {
    my ($node)=@_;
    my $obj=$node->{obj}||'';
    my $obj_str=ref $obj? Dumper($obj) : $obj;
    sprintf "%s-%s: %s",$node->{lo},$node->{hi},$obj_str;
}

########################################################################

sub min_node {
    my ($node)=@_;
    $node->{left}? min_node($node->{left}) : $node;
}

sub max_node {
    my ($node)=@_;
    $node->{right}? max_node($node->{right}) : $node;
}


########################################################################

sub next_bigger {
    my ($self,$i)=@_;
    next_bigger_node($i,$self->root);
}

sub next_bigger_node {
    my ($i,$n)=@_;

    if (node_contains($n,$i)) {
	return $n->{right}? min_node($n->{right}) : undef;
    }
    
    if ($i < $n->{lo}) {
	return $n unless $n->{left};
	return next_bigger_node($i,$n->{left}) || $n;
    }

    if ($i > $n->{hi}) {	# as it must be if we've reached this point
	return undef unless $n->{right};
	return next_bigger_node($i,$n->{right});
    }
}

1;
