package PhonyBone::TaggableA::Image;
use strict;
use warnings;
use Carp;
use Data::Dumper;


# pretty sure this is obsolete


use base qw(PhonyBone::TaggableA::File);

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS %SYNONYMS);
#@AUTO_ATTRIBUTES = qw(photo_id);
#@CLASS_ATTRIBUTES = qw(tablename table_fields indexes uniques dbh_info _dbh primary_id);
%DEFAULTS = ();
%SYNONYMS = ();

Class::AutoClass::declare(__PACKAGE__);


sub _init_self {
    my ($self, $class, $args) = @_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

# generate a url to the image
sub url {
    my ($self,$base_url,$global_photo_dir)=@_;
    my $owner=$self->owner;
    my $path=$self->path;
    $path=~s/$global_photo_dir//;
    $path=~s|^/||;
    my $url="$base_url/images/$owner/$path";
    $url;
}

1;
