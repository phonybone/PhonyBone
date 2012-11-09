package TestPerson;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attributes (sigh...)
use Test::More;

before qr/^test_/ => sub { shift->setup };


sub test_basic : Testcase {
    my ($self)=@_;

    my $fred=new Person(firstname=>'Fred', lastname=>'Flintstone', age=>48);
    cmp_ok($fred->as_str, 'eq', "Fred Flintstone (age 48)", "$fred");
    cmp_ok("$fred", 'eq', "Fred Flintstone (age 48)", "$fred");

    $fred->save;
    # Is there a fred object?
    my %query=%$fred;
    delete $query{_oid};
    isa_ok($fred->_id, 'MongoDB::OID', ref $fred->_id);
    my $records=$self->class->find(\%query);
    cmp_ok(scalar @$records, '==', 1, "got exactly one record for \$fred");
    is_deeply($records->[0], $fred, "record looks like query");
}

sub test_unique : Testcase {
    my ($self)=@_;
    my $fred=new Person(firstname=>'Fred', lastname=>'Flintstone', age=>48);
    $fred->save;
    $fred->save({safe=>1});

    # copy n paste'd from test_basic:
    my %query=%$fred;
    delete $query{_oid};
    isa_ok($fred->_id, 'MongoDB::OID', ref $fred->_id);
    my $records=$self->class->find(\%query);
    cmp_ok(scalar @$records, '==', 1, "got exactly one record for \$fred");
    is_deeply($records->[0], $fred, "record looks like query");

    # this won't bomb, but it won't do anything either (fails silently)
    $self->class->mongo->insert(\%query);
    $records=$self->class->find(\%query);
    cmp_ok(scalar @$records, '==', 1, "got exactly one record for \$fred after insert");
    is_deeply($records->[0], $fred, "record looks like query");

    # this should bomb:
    eval {$self->class->mongo->insert(\%query, {safe=>1})};
    like($@, qr/E11000 duplicate key error index/, 'caught attempt to insert duplicate (safe mode only)');
}


__PACKAGE__->meta->make_immutable;

1;
