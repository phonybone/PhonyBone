#!perl -w 
use strict;

package Options;

#
# Usage:
# Set options with use(), fetch them with get().
# Set default options with useDefaults() (prior to calling get()).
# Access them via %options (no package specifier needed, pollutes the name-space),
# or use the access method option().
#
# Todo: add a "explanations" hash that allows the user to set a short
#       description of each option, to be displayed on dump

use Getopt::Long;
use Exporter ();
our (@EXPORT) = qw(option usage %options);
our (@ISA) = qw(Exporter);

our ($optionsHash, %options, @options, @required, @positional, %descHash);

BEGIN: {
    $optionsHash = \%options;
}

sub use {
    @options = @_;
    
    # clear any previous calls:
    %options = ();
    $optionsHash = \%options;
    @required = ();
    %descHash = ();
}

sub positional {
    push @positional, @_;
}

sub get {
    GetOptions($optionsHash, @options) or die usage();

    # copy @ARGV into $optionsHash as per @positional:
    my $i=0;
    foreach my $p (@positional) {
	my $val=$ARGV[$i++];	# don't want to stomp @ARGV
	$optionsHash->{$p}=$val if defined $val;
    }

    # check for required options:
    push @required, @positional;
    my @missing = ();
    foreach my $opt (@required) {
	push @missing, $opt unless $optionsHash->{$opt};
    }
    if (@missing > 0) {
	warn sprintf "missing options: %s\n", join(', ', (map "'$_'", @missing));
	die usage();
    }


    # copy into options hash for user convenience:
    %options = %$optionsHash if ($optionsHash != \%options);
}

# build a usage string
# pass in names of required args (or get them from @positional)
sub usage {
    my @args=(@positional, @_);
    my $usage = $0;
    $usage =~ s|.*/||;
    $usage = 'usage: ' . $usage . ' ';
    $usage.=join(" ", map {"<$_>"} @args);
    my $format = "%-20s %-10s %-10s %s\n";
    $usage .= sprintf "\n$format", 'Option', 'Default', 'Required', 'Description';
    foreach my $opt (@options) {
#	$usage .= "\t$opt";
	$opt =~ s/[=:]\w$//;	# chop type specifier so that grep, below, works

	my $default = ref $optionsHash->{$opt} || $optionsHash->{$opt} || '';
	my $desc = $descHash{$opt} || '';
	my $reqd = (grep /^$opt$/, @required)? 'yes' : 'no';
	$usage .= sprintf $format, $opt, $default, $reqd, $desc;
	next;
	$usage .= "\tdef=$default";
	$usage .= "\t$descHash{$opt}" if $descHash{$opt};
	$usage .= "\t(REQUIRED)" if grep /^$opt$/, @required;
	$usage .= "\n";
    }
    return $usage;
}

sub dump {
    foreach my $opt (keys %$optionsHash) {
	if (ref $optionsHash->{$opt} eq 'ARRAY') {
	    warn sprintf "options{$opt} is %s\n", join(', ', @{$optionsHash->{$opt}});
	} else {
	    warn "options{$opt} is $optionsHash->{$opt}\n" if defined $optionsHash->{$opt};
	}
    }
}

# usage: ?
# 
sub useDefaults {
    my %argHash = @_;
    foreach my $opt (keys %argHash) {
	$optionsHash->{$opt} = $argHash{$opt};
    }
}


# return an option value by name:
sub option {
    my $opt = shift;
    return $optionsHash->{$opt}
}

# return list of required (named, not positional) options:
sub required {
    @required = @_;
}

# use a given hash as the options hash.
# This is useful if you want to be able to modify config values from
# the command line - but be sure to call this AFTER calling Options::use()
sub setHash {
    my $hashRef = shift;
    die "not a hash ref" unless ref $hashRef eq 'HASH';
    $optionsHash = $hashRef;

    # make all keys in hash ref usable as options:
    foreach my $key (keys %$hashRef) {
	my $value = $hashRef->{$key};
	my $type;
	if ($value =~ /^[-+]?\d+$/) {
	    $type = 'i';
	} elsif ($value =~ /^[-+]?\d+\.?\d+([eE]-?\d+)?$/) {
	    $type = 'f';
	} else {
	    $type = 's';
	}
	push @options, "$key:$type";
    }
}

sub setDescriptions {
    my $descHash = shift;
    %descHash = %$descHash;
}

# Process and return options that can be either a list of values OR
# the name of a file containing a "\n"-separated list of values.
# returns a list[ref] of values (empty list if no valid values specified)
sub file_or_list {
    my ($opt)=@_;

    my $opt_list=$options{$opt} or return undef;
    my @values=();
    if (-r $opt_list->[0]) {
	open (FILE, $opt_list->[0]) or die "Can't open ", $opt_list->[0], " for reading??? $!";
	@values=map {chomp; $_} <FILE>;
	close FILE;
    } elsif (ref $opt_list eq 'ARRAY') {
	@values=@$opt_list;
    } else {
	die "Don't know how to convert to list of gse's: ", Dumper($opt_list);
    }

    wantarray? @values:\@values;
}




# nice idea, but doesn't handle non-argument options correctly (assigns a value).
#sub stringify { join(' ', map { $options{$_}? "-$_=$options{$_}" : '' } @_) }    

1;
