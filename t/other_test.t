use Mojo::Base -strict;

use Test::More;
use Test::Fatal qw(dies_ok);
use Mojo::File;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::JSON::Patch;

my $file  = File::Spec->catfile(File::Basename::dirname(__FILE__), 'tests.json');
my $path  = Mojo::File->new($file);
my $json  = $path->slurp;
my $tests = decode_json($json);

for my $test (@{$tests}) {
  my $p = Mojo::JSON::Patch->new($test->{patch});
  is_deeply $p->apply($test->{doc})->data, $test->{expected}, $test->{comment} if (defined($test->{expected}));
  dies_ok { $p->apply($test->{doc}) } 'Dies as expected' if defined($test->{error});
}

done_testing(scalar @{$tests});
