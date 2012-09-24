use strict;
use warnings;

package PhonyBone::FileUtilities;

# $Id: FileUtilities.pm,v 1.7 2009/07/13 20:56:46 vcassen Exp $

use Carp;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(slurpFile spitString appendFile directory_crawl 
		parse3 dir basename suffix filename dir_files
		directory_iterator file_iterator is_empty
		dief warnf
		file_lines substitute);


# read the entire contents of a file
# confesses on error
sub slurpFile {
    my $filename = shift or confess "no filename";
    open (FILE, "$filename") or confess "Can't open $filename: $!";

    my $oldFilehandle = select FILE;
    my $oldRecordSep = $/;
    undef $/;
    my $contents = <FILE>;	# slurp!
    $/ = $oldRecordSep;
    select $oldFilehandle;
    close FILE;
    return $contents;
}



# write a string as the contents of a file (overwrites any previous
# contents).
# throws exceptions as needed
sub spitString {
    my $string = shift;
    my $filename = shift;
    my $lockFlag = shift || '';

    open (FILE, ">$filename.tmp") or
	confess "Unable to open $filename.tmp for writing: $!\n";

    if ($lockFlag) {
	use Fcntl ':flock';
	flock(FILE, LOCK_EX);
	seek(FILE, 0, 2);
    }
    print FILE $string or
	confess "Unable to write to $filename: $!\n";

    flock(FILE, LOCK_UN) if $lockFlag;
    close FILE or confess "Unable to close $filename: $!\n";

    rename "$filename.tmp", "$filename" or confess "Unable to rename '$filename.tmp' to '$filename': $!\n";

    return 1;
}


sub appendFile {
    my $record = shift;
    my $filename = shift;

    open (FILE, ">>$filename") or
	confess "Unable to open $filename for appending: $!\n";

    print FILE $record or
	confess "Unable to write to $filename: $!\n";

    close FILE or confess "Unable to close $filename: $!\n";
    return 1;
}


sub prependFile {
    my $record = shift;
    my $filename = shift;

    my $contents = slurpFile($filename);
    open (FILE, ">$filename") or
	confess "Can't open $filename for writing: $!\n";
    print FILE $record;
    print FILE $contents;
    close FILE;
    1;
}

# return a list[ref] of all the files in a directory whose name matches a regex filter.
# omit filter to get all entries.
sub dir_files {
    my ($dir,$filter)=@_;
    opendir (DIR,$dir) or confess "Can't open '$dir': $!";
    $filter||='.';
    my @files=grep /$filter/, readdir DIR;
    closedir DIR;
    wantarray? @files:\@files;
}


sub directory_crawl {
    my $dir = shift or confess "no dir";
    my $dir_hook = shift || sub { };
    my $dir_args = shift;
    my $file_hook = shift || sub { };
    my $file_args = shift;
    my $level = shift || 0;

    opendir(DIR, $dir) or confess "Can't open $dir: $!";
    my @entries = grep !/^\./, readdir DIR;
    closedir DIR;

    my @subdirs;
    foreach my $entry (@entries) {
	my $path = "$dir/$entry";
	if (-d $path) {
	    push @subdirs, "$entry";
	    &$dir_hook($path, $level, $dir_args) if ref $dir_hook eq 'CODE';
	} else {
	    &$file_hook($path, $level, $file_args) if ref $file_hook eq 'CODE';
	}
    }

    foreach my $subdir (@subdirs) {
	directory_crawl("$dir/$subdir", $dir_hook, $dir_args, $file_hook, $file_args, $level+1);
    }
}


sub parse3 {
    my $path=shift or confess "no path";

    # I don't think there is a lexigraphical way to differentiate /dir from /file:
    return wantarray? ($path,'',''):[$path,'',''] if -d $path;

    my ($d,$f,$b,$s);

    if ($path =~ m|/|) {
	# split into dir and file.suffix:
	($d,$f) = $path =~ m|(.*)/(.*)|g;
    } else {
	$d = '';
	$f = $path;
    }
    ($b,$s) = $f =~ /([^.]*)\.?(.*)/;
    wantarray? ($d,$b,$s):[$d,$b,$s];
}



sub dir { (parse3($_[0]))[0]; }
sub basename { (parse3($_[0]))[1]; }
sub suffix { (parse3($_[0]))[2]; }
sub filename { my @p=parse3($_[0]);join('.',$p[1],$p[2])}

########################################################################

sub directory_iterator {
    my ($directory,$subref,$fuse)=@_;

    $fuse=-1 unless defined $fuse;
    opendir (DIR, $directory) or die "Can't open $directory: $!\n";
    while ($_=readdir DIR) {
	chomp;
	$subref->($_);
	last if --$fuse==0;
    }
    close DIR;
}


sub file_iterator {
    my ($filename,$subref,$fuse)=@_;

    $fuse=-1 unless defined $fuse;
    open (FILE, $filename) or die "Can't open $filename: $!\n";
    while (<FILE>) {
	chomp;
	$subref->($_);
	last if --$fuse==0;
    }
    close FILE;
}

########################################################################

# report if the file or directory is empty:
# throw exception if $path doesn't exist or is unreadable
# only advantage to this of "-z $filename" is that it works on directories indisciminantly.
sub is_empty {
    my $path=shift;
    die "$path: no such file or directory" unless -e $path;
    die "$path: unreadable" unless -r $path;

    return  -z $path if -f $path;

    local *DIR;
    opendir(DIR, $path) or die "wtf??? Can't open '$path': $!";
    my @files=grep !/^\.\.?$/, readdir DIR;
    closedir DIR;
    return scalar @files==0;
}

########################################################################


sub dief {
    my ($format, @args)=@_;
    confess "no format" unless $format;
    Carp::cluck "no args" unless @args;
    @args=map {defined $_? $_ : ''} @args;
    my $warning;
    {
	local $SIG{__WARN__}=sub { confess @_ };
	$warning=sprintf($format, @args);
    }
    if ($warning!~/\n$/) {
	my ($p,$f,$l)=caller;
	$warning.=" at $f, line $l\n";
    }
    die $warning;
}

sub warnf {
    my ($format, @args)=@_;
    my $warning;
    {
	local $SIG{__WARN__}=sub {confess @_};
	$warning=sprintf($format, @args);
    }
    if ($warning!~/\n$/) {
	my ($p,$f,$l)=caller;
	$warning.=" at $f, line $l\n";
    }
    warn $warning;
}

########################################################################

# return the lines of an entire file as a list[ref]:
sub file_lines {
    my ($fn, %args)=@_;
    local *FILE;
    open(FILE, $fn) or die "Can't open $fn: $!\n";
    my @lines=<FILE>;
    if ($args{chomp}) {
	chomp $_ for @lines;
    }
    close FILE;
    wantarray? @lines:\@lines;
}    

########################################################################

sub substitute {
    my ($filename, $regex, $repl, $opts)=@_;
    $opts||={};
    my $lines=file_lines($filename);
    foreach (@$lines) {
	s/$regex/$repl/g;
    }

    unless ($opts->{no_backup}) {
	rename $filename, "$filename.bak" or die "Can't rename '$filename' to '$filename.bak': $!\n";
    }

    spitString(join('', @$lines), $filename);
}

1;
