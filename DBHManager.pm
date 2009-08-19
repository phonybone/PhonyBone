package PhonyBone::DBHManager;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Exporter;
use DBI;

our @EXPORT_OK=qw(get_dbh);
our %dbh_info=(
	       default=>{default=>{engine=>'mysql',
				   host=>'localhost',
				   user=>$ENV{USER},
				   password=>'',
			       },
		     },
	       # laptop
	       linux=>{default=>{engine=>'mysql',
				 host=>'localhost',
				 user=>$ENV{USER},
				 password=>''},
		   },
	       pandora=>{default=>{engine=>'mysql',
				   host=>'localhost',
				   db_name=>'tag_sandbox',
				   user=>$ENV{USER},
				   password=>''},
		     },
	       'fala.systemsbiology.net'=>{default=>{engine=>'mysql',
				host=>'localhost',
				db_name=>'vcassen',
				user=>'',
				password=>'',
			    },
		   },
	       'victor-cassens-mac-mini.local'=>{default=>{engine=>'mysql',
				host=>'localhost',
				db_name=>'vcassen',
				user=>'',
				password=>'',
			    },
		   },
	       'host241.hostmonster.com'=>{default=>{engine=>'mysql',
				host=>'localhost',
				db_name=>'pnwmomor_pnwmom',
				user=>'pnwmomor_victor',
				password=>'Bsa441',
			    },
		   },						 

	       );
# keys are hostname->group
our %db_name=(
	      pandora=>{
		  persistable=>'persistable',
		  tags=>'tag_sandbox',
	      },
	      'fala.systemsbiology.net'=>{
		  persistable=>'vcassen',
		  tags=>'vcassen',
	      },
	      'host241.hostmonster.com'=>{
		  persistable=>'pnwmomor_pnwmom',
		  tags=>'pnwmomor_pnwmom',
	      },
	      );

sub new { bless {}, __PACKAGE__ }


sub dbh_info {
    my $class=shift||'default';
    my $hostname=`hostname`;
    chomp $hostname;
    my $dbh_info=$dbh_info{$hostname} || $dbh_info{default};
    $dbh_info=$dbh_info->{$class} || $dbh_info->{default};
}

sub get_dbh {
    my ($self,$class,$attrs)=@_;
    $class=ref $class || $class;
    $attrs||={};
    
    my $hostname=`hostname`;
    chomp $hostname;
    my $dbh_info=dbh_info($hostname) or confess "no dbh_info for host '$hostname'";

    my $db_name=$self->db_name($class,$hostname);
    confess "class '$class' does not define a db_name or dbh_group" unless $db_name;
    
    my ($engine,$host,$db_type,$user,$password)=@{$dbh_info}{qw(engine host db_type user password)};
    $engine||='mysql';		# default, lazy me
    $db_type=$engine eq 'mysql'? 'database':'db'; # second value might be wrong...
    my $dsn="DBI:$engine:host=$host:$db_type=$db_name";
    my $dbh=DBI->connect($dsn,$user,$password,$attrs);

}

sub db_name {
    my ($self,$class,$hostname)=@_;
    $class=ref $class || $class;
    do {$hostname=`hostname`; chomp $hostname} unless $hostname;
#    my $db_name=($class->db_name($class)) if $class->can('db_name'); # causes infinite recursion
    my $group=$class->dbh_group if $class->can('dbh_group');
    my $db_name=$db_name{$hostname}->{$group} if $class->can('dbh_group');
    $db_name;
}

