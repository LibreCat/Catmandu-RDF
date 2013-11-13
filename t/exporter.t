use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Exporter::RDF'; }
require_ok $pkg;

my $file = "";
my $data = { # example copied from RDF::Trine::Model
  "http://example.com/subject1" => {
    "http://example.com/predicate1" => [
        'Foo@en',
        "Bar^<http://example.com/datatype1>" 
    ],
  },
  "_:bnode1" => {
    "http://example.com/predicate2" => [
      "http://example.com/object2",
    ],
    "http://example.com/predicate2" => [
      "_:bnode3",
    ],
  },
};

my $exporter = $pkg->new(file => \$file, type => 'ttl');
isa_ok $exporter, $pkg;

is $exporter->count, 0, 'count is zero';
$exporter->add($data);
$exporter->commit;

# normalize
$file =~ s/("Foo".+), ("Bar".+) ./$2, $1 ./;
$file = join "\n", sort split "\n", "$file";
$file .= "\n" unless $file =~ /\n$/m;

is $file, <<'RDF', 'serialize Turtle';
<http://example.com/subject1> <http://example.com/predicate1> "Bar"^^<http://example.com/datatype1>, "Foo"@en .
_:bnode1 <http://example.com/predicate2> _:bnode3 .
RDF

is $exporter->count, 1, 'count is always one';

done_testing;
