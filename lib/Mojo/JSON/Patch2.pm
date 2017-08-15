package Mojo::JSON::Patch;
use Mojo::Base 'Mojo::JSON::Pointer';

use Carp 'croak';
use Mojo::Path;

sub apply {
  my ($self, $patch) = @_;

  for my $operation (@{$patch}) {
    my $op = '_' . $operation->{'op'};
    my $other = $operation->{'value'} //= $operation->{'from'};
    $self->$op($operation->{'path'}, $other);
  }

  return $self->data;
}

sub new { @_ > 1 ? shift->SUPER::new(data => shift) : shift->SUPER::new }

sub _add {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $val  = shift;

  if ("$path" eq '/') {
    $self->data($val);
  }
  else {
    my $leaf = pop @$path;
    my $parent = ("$path" eq '/') ? $self->data : $self->get("$path");
    croak 'ADD: Non-exising JSON node' unless $parent;

    if (ref $parent eq 'ARRAY') {
      if ($leaf =~ m{-}) {
        push @{$parent}, $val;
      }
      else {
        croak 'ADD: Non-existing JSON array index' if (scalar @{$parent} < $leaf);
        splice(@{$parent}, $leaf, 0, $val);
      }
    }
    elsif (ref $parent eq 'HASH') {
      $parent->{$leaf} = $val;
    }
  }

  return $self;
}

sub _remove {
  my $self = shift;
  my $path = Mojo::Path->new(shift);

  croak 'REMOVE: Non-exising JSON node' unless $self->contains("$path");
  my $leaf = pop @$path;
  my $parent = ("$path" eq '/') ? $self->data : $self->get("$path");

  if (ref $parent eq 'ARRAY') {
    splice(@{$parent}, $leaf, 1);
  }
  elsif (ref $parent eq 'HASH') {
    delete($parent->{$leaf});
  }

  return $self;
}

sub _replace {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $val  = shift;

  if ("$path" eq '/') {
    $self->data($val) if defined($self->data);
  }
  else {
    my $leaf = pop @$path;
    my $parent = ("$path" eq '/') ? $self->data : $self->get("$path");
    croak 'REPLACE: Non-exising JSON node' unless $parent;

    if (ref $parent eq 'ARRAY') {
      $parent->[$leaf] = $val;
    }
    elsif (ref $parent eq 'HASH') {
      $parent->{$leaf} = $val;
    }
  }

  return $self;
}

sub _copy {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $from = Mojo::Path->new(shift);

  croak 'COPY: Non-exising JSON node' unless $self->contains("$from");
  my $val = $self->get("$from");

  my $leaf = pop @$path;
  croak 'COPY: Non-exising JSON node' unless $self->contains("$path");
  my $parent = $self->get("$path");

  if (ref $parent eq 'ARRAY') {
    if ($leaf =~ m{-}) {
      push @{$parent}, $val;
    }
    else {
      croak 'ADD: Non-existing JSON array index' if (scalar @{$parent} > $leaf);
      splice(@{$parent}, $leaf, 0, $val);
    }
  }
  elsif (ref $parent eq 'HASH') {
    $parent->{$leaf} = $val;
  }

  return $self;
}

sub _move {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $from = Mojo::Path->new(shift);
  my $val;

  croak 'MOVE: Non-exising JSON node' unless $self->contains("$from");
  my $from_leaf   = pop @$from;
  my $from_parent = $self->get("$from");
  if (ref $from_parent eq 'ARRAY') {
    $val = splice(@{$from_parent}, $from_leaf, 1);
  }
  elsif (ref $from_parent eq 'HASH') {
    $val = delete($from_parent->{$from_leaf});
  }

  my $leaf = pop @$path;
  croak 'MOVE: Non-exising JSON node' unless $self->contains("$path");
  my $parent = $self->get("$path");

  if (ref $parent eq 'ARRAY') {
    if ($leaf =~ m{-}) {
      push @{$parent}, $val;
    }
    else {
      croak 'ADD: Non-existing JSON array index' if (scalar @{$parent} > $leaf);
      splice(@{$parent}, $leaf, 0, $val);
    }
  }
  elsif (ref $parent eq 'HASH') {
    $parent->{$leaf} = $val;
  }

  return $self;
}

sub _test {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $val  = shift;
  croak 'TEST: Unsupported operation';
}

1;

=encoding utf8

=head1 NAME

Mojo::JSON::Patch - JSON Patch

=head1 SYNOPSIS

  use Mojo::JSON::Patch;

  my $patch = Mojo::JSON::Patch->new({foo => [23, 'bar']});
  my $patched = $patch->apply([{op => 'add', path => '/foo', bar => 'baz'}]);

=head1 DESCRIPTION

L<Mojo::JSON::Patch> is an implementation of
L<RFC 6901|http://tools.ietf.org/html/rfc6901>.

=head1 ATTRIBUTES

L<Mojo::JSON::Patch> implements the following attributes.

=head2 data

  my $data = $patch->data;
  $patch = $patch->data({foo => 'bar'});

Data structure to be processed.

=head1 METHODS

L<Mojo::JSON::Patch> inherits all methods from L<Mojo::JSON::Pointer> and implements
the following new ones.

=head2 apply

  my $patched = $patch->apply([{op => 'add', path => '/foo', value => 'baz'}]);

Apply patch to L</"data">, contains a value that can be identified with the given JSON
Patch.

  # {foo => 'baz', baz => [4, 5, 6]}
  Mojo::JSON::Patch->new({foo => 'bar', baz => [4, 5, 6]})->apply([{op => 'replace', path => '/foo', value => 'baz'}]);

=head2 new

  my $patch = Mojo::JSON::Patch->new;
  my $patch = Mojo::JSON::Patch->new({foo => 'bar'});

Build new L<Mojo::JSON::Patch> object.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
