package PhonyBone::CatalystHelpers;
use Moose::Role;

sub add_to_page {
    my ($self, $src, $where)=@_;
    my $target=$self->path_to(File::Spec->splitdir($src));
#    -r $target or die "'$target': no such file";
    push @{$self->stash->{page}->{$where}}, $src;
}

sub add_js_script {
    my ($self, $src)=@_;
    $self->add_to_page($src, 'scripts');
}

sub add_css {
    my ($self, $src)=@_;
    $self->add_to_page($src, 'css_srcs');
}

sub title {
    my ($self, $title)=@_;
    $self->stash->{page}->{title}=$title if $title;
    $self->stash->{page}->{title};
}

sub push_stack {
    my ($self, $caller, $msg)=@_;
    my $action_name=$self->stack->[-1]->name;
    my $action=$self->controller->action_for($action_name);
    my $uri=$action? $self->uri_for($action) : undef;
    push @{$self->stash->{matches}}, {ref($caller) => {$action=>$uri, msg=>$msg}};
}

1;
