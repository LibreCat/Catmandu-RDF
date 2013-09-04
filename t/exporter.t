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
      { 'type'=>'literal', 'value'=>"Foo", 'lang'=>"en" },
      { 'type'=>'literal', 'value'=>"Bar", 'datatype'=>"http://example.com/datatype1" },
    ],
  },
  "_:bnode1" => {
    "http://example.com/predicate2" => [
      { 'type'=>'uri', 'value'=>"http://example.com/object2" },
    ],
    "http://example.com/predicate2" => [
      { 'type'=>'bnode', 'value'=>"_:bnode3" },
    ],
  },
};

my $exporter = $pkg->new(file => \$file, type => 'ttl');
isa_ok $exporter, $pkg;

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

done_testing;

__END__

# Support a subset of JSON-LD
# TODO: test
{
    '@id'  => 'http://example.org/subject1',
    'dc:title' => 'Example',
    'http://example.org/predicate' => { '@id' => 'http://example.com/object2' },
    'dc:modified' => {
        "@value": "2010-05-29T14:17:39+02:00",
        "@type": "http://www.w3.org/2001/XMLSchema#dateTime"
    }
}

set_field('@id','http://example.org/subject1');
set_field('dc:title','Example');
set_field('dc:modified.@value',"2010-05-29T14:17:39+02:00");
set_field('dc:modified.@type','xsd:dateTime');
