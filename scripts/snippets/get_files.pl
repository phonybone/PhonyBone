use strict;
use warnings;
use vars qw(%options);

# given a list of files/directories, compile a list of fully qualified
# paths, expanding the directories recursively if $options{r} is set.
# also uses $options{filter_re} to filter files.
sub get_files {
    my @inputs=@_;
    my @files;
    foreach (@_) {
	my $is_dir=-d $_;
	if ($is_dir && $options{recur}) {
	    my $regex=$options{filter_re};
	    opendir(DIR,$_) or die "Can't open $_ for reading: $!\n";
	    my @sfiles=grep /$regex/, readdir DIR;
	    closedir DIR;
	    foreach my $file (@sfiles) {
		push @files, "$_/$file";
		push @files, get_files("$_/$file") if -d "$_/$file";
	    }
	}
	elsif (-r) {
	    push @files, $_;
	} else {
	    warn "skipping '$_'\n" if $options{d};
	}
    }
    wantarray? @files:\@files;
}


sub fix {
    my $dir=shift;
    my $pwd=`pwd`; chomp $pwd;
    $dir="$pwd/$dir" if $dir=~/^\./;
    $dir=~s|/./|/|g;
    while ($dir=~s|(/\w+/\.\.)||) { }
    $dir=~s|/+$||;
    $dir;
}


1;
