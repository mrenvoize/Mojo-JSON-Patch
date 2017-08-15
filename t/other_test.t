use Mojo::Base -strict;

use Test::More;
use Mojo::File;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::JSON::Patch;

my $file  = File::Spec->catfile(File::Basename::dirname(__FILE__), 'tests.json');
my $path  = Mojo::File->new($file);
my $json  = $path->slurp;
my $tests = decode_json($json);

my $count;
for my $test (@{$tests}) {
  my $p = Mojo::JSON::Patch->new($test->{patch});
  if (defined($test->{expected})) {
    is_deeply $p->apply($test->{doc})->data, $test->{expected}, $test->{comment};
  }
}

done_testing;
