package PhonyBone::OrderedList;
use base qw(Class::AutoClass);
use warnings;
use strict;
use Data::Dumper;
use Carp;

########################################################################
# Holds an ordered list of arbitrary objects, but each object must define
# a method 'primary_id' which returns a unique id for that item.
# 
# Objects are stored in a hash: k=primary_id, v={
#   item_id=>$item_id,
#   item=>$item,
#   next_id=>id of following item
#   prev_id=>id of preceding item
# 
# TODO:
# Allow lists to only store ids, and not items
# Change 'item' to 'obj'
# Allow lists to store objects without ids? (would generate our own, maybe?)
########################################################################

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES = qw(items first_id last_id ids_only);
@CLASS_ATTRIBUTES=qw();
%DEFAULTS = (
	     items=>{},
	     );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

########################################################################

sub add_before {
    my ($self,%argHash)=@_;

    my $next_id=$argHash{before}; # can be missing; implies add at beginning
    return $self->add_front(%argHash) unless defined $next_id;

    my $new_h=$self->_new_element(%argHash);
    my $new_id=$new_h->{item_id};
    confess "'$new_id' already exists" if $self->items->{$new_id};
    return $self->_add_to_empty($new_h) if $self->is_empty;
    my $items=$self->items;
    $items->{$new_id}=$new_h;

    my $next_h=$items->{$next_id} or confess "no next item for next_id='$next_id'";
    $new_h->{next_id}=$next_id;
    $new_h->{prev_id}=$next_h->{prev_id};

    my $prev_id=$next_h->{prev_id};
    if (defined $prev_id) {
	my $prev_h=$items->{$prev_id} or confess "no prev item for prev_id='$prev_id'???";
	$prev_h->{next_id}=$new_id;
	$new_h->{prev_id}=$prev_id;
    } else {		# there was no previous, this is first
	$self->first_id($new_id);
    }

    $next_h->{prev_id}=$new_id;
    $self;
}

sub add_after {
    my ($self,%argHash)=@_;

    my $prev_id=$argHash{after}; # can be missing; implies add at end
    return $self->add_end(%argHash) unless defined $prev_id;

    my $new_h=$self->_new_element(%argHash);
    my $new_id=$new_h->{item_id};
    confess "'$new_id' already exists" if $self->items->{$new_id};
    return $self->_add_to_empty($new_h) if $self->is_empty;
    my $items=$self->items;
    $items->{$new_id}=$new_h;

    my $prev_h=$items->{$prev_id} or confess "no prev item for prev_id='$prev_id'???";
    $new_h->{prev_id}=$prev_id;
    $new_h->{next_id}=$prev_h->{next_id};
    
    my $next_id=$prev_h->{next_id};
    if (defined $next_id) {
	my $next_h=$items->{$next_id} or confess "no next item for next_id='$next_id'???";
	$next_h->{prev_id}=$new_id;
    } else {			# there was no next, this is the last
	$self->last_id($new_id);
    }
    $prev_h->{next_id}=$new_id;
    $self;
}

# add an item/id pair to the front of the list
# if only item is given, extract id
# if only id is given, ignore item (or if $self->ids_only is set)
sub add_front {
    my ($self,%argHash)=@_;
    my $new_h=$self->_new_element(%argHash);
    my $id=$new_h->{item_id};
    confess "id '$id' already exists" if defined $self->items->{$id};
    $self->items->{$id}=$new_h;

    my ($old_first_id)=$self->first_id;
    if (defined $old_first_id) {
	my $old_first=$self->items->{$old_first_id};
	$new_h->{next_id}=$old_first_id;
	$old_first->{prev_id}=$id;
    } else {
	$self->last_id($id);	# there was no last
    }
    $self->first_id($id);
    $self;
}

sub add_end {
    my ($self,%argHash)=@_;
    my $new_h=$self->_new_element(%argHash);
    my $id=$new_h->{item_id};
    confess "id '$id' already exists" if defined $self->items->{$id};
    $self->items->{$id}=$new_h;

    my $old_last_id=$self->last_id;
    if (defined $old_last_id) {
	my $old_last=$self->items->{$old_last_id};
	$new_h->{prev_id}=$old_last_id;
	$old_last->{next_id}=$id;
    } else {
	$self->first_id($id);	# there was no first
    }
    $self->last_id($id);
    $self;
}

sub is_empty {
    my ($self)=@_;
    return scalar keys %{$self->items}==0;
}

sub _add_to_empty {		# TODO: allow for $item to be undef if $self->ids_only
    my ($self,$item,$id)=@_;
    confess "no id" unless defined $id;
    $self->items->{$id}->{item_id}=$id;
    $self->items->{$id}->{item}=$item if defined $item;
    $self->first_id($id);
    $self->last_id($id);
    $self;
}

# extract args 'item' and 'item_id'
# return a hash containing the item and item_id as appropriate
sub _new_element {
    my ($self,%argHash)=@_;
    my ($item,$id)=@argHash{qw(item id)};
    $id=$argHash{item_id} unless defined $id;
    if ($item && !defined $id) {# try to get id from $item->primary_id
	if (my $class=ref $item) {
	    my $subref;
	    eval {$subref=$item->can('primary_id')};
	    if (ref $subref eq 'CODE') {
		$id=$item->primary_id;
		confess "'$item' doesn't have a primary id" unless defined $id;
	    } else {			# else either barf or generate $id
		confess "class '$class' doesn't define primary_id() and no id passed";
	    }
	} else {		# $item is scalar, no id, so equate the two
	    $id=$item;
	}
    } 
    
    confess "no id in ",Dumper(\%argHash) unless defined $id;
    confess "'$id' not a scalar" if ref $id;
    confess "no item in ",Dumper(\%argHash) unless $item || $self->ids_only;
    confess "item passed to ids_only list" if $item && $self->ids_only;
    # other cases?
    my $h={item_id=>$id};
    $h->{item}=$item if defined $item;
    $h;
}

sub _extract_item_n_id_old {
    my ($self,%argHash)=@_;
    my ($item,$id)=@argHash{qw(item item_id)};

    if (@_==0) {
	confess "no item or id";

    } elsif (@_==1) {
	if (ref $_[0]) {
	    my $subref;
	    eval {$subref=$_[0]->can('primary_id')};
	    if (ref $subref eq 'CODE') {
		$item=shift;
		$id=$item->primary_id;
		confess "'$item' doesn't have a primary id" unless defined $id;
	    } else {
		my $class=ref $_[0];
		confess "class '$class' doesn't define primary_id()";
	    }
	} elsif ($self->ids_only) {
	    $id=shift;		
	} else {
	    confess "non-ref '$_[0]' passed to list that expects objects";
	}
	confess "no item" unless $item || $self->ids_only; # more checks
	confess "no id" unless defined $id;
    } else {
	($item,$id)=@_[0..1];	# don't know why there would really be more than two args...
	confess "id '$id' not a scalar" if ref $id;
    }
    ($item,$id);
}

sub item {
    my ($self,$id)=@_;
    $self->items->{$id};
}

sub n_items {
    my ($self)=@_;
    scalar keys %{$self->items};
}

# return all ids in order
sub all_ids {
    my ($self)=@_;
    my @ids;
    my $items=$self->items;
    my $id=$self->first_id or return wantarray? ():[];

    while (my $item=$items->{$id}) {
	push @ids,$id;
	$id=$item->{next_id} or last;
    }
    wantarray? @ids:\@ids;
}

sub id_after { $_[0]->items->{$_[1]}->{next_id} }
sub item_after { $_[0]->items->{$_[0]->id_after($_[1])} }
sub id_before { $_[0]->items->{$_[1]}->{prev_id} }
sub item_before { $_[0]->items->{$_[0]->id_before($_[1])} }

# return the first or last item in the list (not the hash element)
sub first_item { $_[0]->items->{$_[0]->first_id}->{item}}
sub last_item { $_[0]->items->{$_[0]->last_id}->{item}}

sub delete {
    my ($self,%argHash)=@_;
    my $id=$argHash{id} or confess "no id";
    my $h=$self->items->{$id};
#    warn "h is ",Dumper($h);

    # delete prev and next nodes as appropriate
    my $next_id=$h->{next_id};
    my $prev_id=$h->{prev_id};
    $self->items->{$prev_id}->{next_id}=$next_id if defined $prev_id;
    $self->items->{$next_id}->{prev_id}=$prev_id if defined $next_id;
    delete $self->items->{$id};

    # also have to account if $id is first or last or only
    if ($self->is_empty) {
	$self->first_id(undef);
	$self->last_id(undef);
    } elsif ($self->n_items==1) {
	my $only_id=(keys %{$self->items})[0];
	$self->first_id($only_id);
	$self->last_id($only_id);
    } elsif ($id eq $self->first_id) {
	$self->first_id($next_id);
    } elsif ($id eq $self->last_id) {
	$self->last_id($prev_id);
    }

    $self;
}

sub delete_before {
    my ($self,%argHash)=@_;
    my $id=$argHash{id} or confess "no id";
    my $h=$self->items->{$id} or return $self; # no such $id
    my $prev_id=$h->{prev_id} or return $self; # $id must be first
    $self->delete(id=>$prev_id);
}

sub delete_after {
    my ($self,%argHash)=@_;
    my $id=$argHash{id} or confess "no id";
    my $h=$self->items->{$id} or return $self;
    my $next_id=$h->{next_id} or return $self;
    $self->delete(id=>$next_id);
}

sub delete_first {
    my ($self,%argHash)=@_;
    my $id=$self->first_id;
    return $self unless defined $id;	# empty list
    $self->delete(id=>$id);
}

sub delete_last {
    my ($self,%argHash)=@_;
    my $id=$self->last_id;
    return $self unless defined $id;	# empty list
    $self->delete(id=>$id);
}

1;
