package Mojo::JSON::Patch;
use Mojo::Base 'Mojo::JSON::Pointer';

use Carp 'croak';
use Mojo::Path;

sub set {
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

package main;
use Test::More;

my $p = Mojo::JSON::Patch->new({foo => {bar => [24, 42]}});

is $p->get('/foo/bar/0'), 24, 'get original value';
is $p->set('/foo/bar/1', 54), $p, 'set new value';
is $p->get('/foo/bar/1'), 54, 'get new value';
is $p->set('/foo/bar/1', {baz => 2}), $p, 'set new value as json object';
is $p->get('/foo/bar/1/baz'), 2, 'get new nested balue';
is $p->set('/foo/bar/1', {1 => {2 => [3,4]}}), $p, 'set new value as json object';
is $p->get('/foo/bar/1/1/2/0'), 3, 'get new nested balue';
is $p->set('/foo/bar/3', 7), $p, 'set second array element';
is $p->get('/foo/bar/3'), 7, 'get second array element';

eval { $p->set('/foo/bar/4/4', 54) };
like $@, qr{Non-exising}, 'non exising';

is $p->set('/foo/bar', [64]), $p, 'set /foo/bar';
is $p->get('/foo/bar/0'), 64, 'get new array';

done_testing;
