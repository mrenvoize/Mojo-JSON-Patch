package Mojo::JSON::Patch;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::JSON::Pointer;
use Mojo::Path;

has 'patch';

sub new { @_ > 1 ? shift->SUPER::new(patch => shift) : shift->SUPER::new }

sub _set {
  my $self = shift;
  my $path = Mojo::Path->new(shift);
  my $val  = shift;

  my $leaf   = pop @$path;
  croak 'Non-exising JSON node' unless $self->contains("$path");
  my $parent = $self->get("$path");

  if (ref $parent eq 'ARRAY') {
    $parent->[$leaf] = $val;
  }
  elsif (ref $parent eq 'HASH') {
    $parent->{$leaf} = $val;
  }

  return $self;
}

1;
