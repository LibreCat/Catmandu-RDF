use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Importer::RDF'; }
require_ok $pkg;

my $importer = $pkg->new(file => 't/example.ttl', ns => 0);
isa_ok $importer, $pkg;

my $input = $importer->to_array;
is_deeply $input, [
   {
     'http://example.org' => {
        a => [ '<http://www.w3.org/2000/01/rdf-schema#Resource>' ],
        'http://example.org/foo' => [ 'bar@en' ],
        'http://purl.org/dc/elements/1.1/title' => [ 'BAR@' ],
        'http://purl.org/dc/elements/1.1/extent' => [ '42^<http://www.w3.org/2001/XMLSchema#integer>' ],
     },
   }
], 'disable namespace prefixes';

$importer = $pkg->new(file => 't/example.ttl', ns => 1);
$input = $importer->to_array;

is_deeply $input, [ {
     'http://example.org' => {
        a         => [ 'rdfs:Resource' ],
        dc_title  => [ 'BAR@' ],
        dc_extent => [ '42^xs:integer' ],
        'http://example.org/foo' => [ 'bar@en' ],
     },
   }
], 'default namespace prefixes';

# TODO: check round-trip
=cut
use Catmandu::Exporter::RDF;
my $out = "";
my $exporter = Catmandu::Exporter::RDF->new(file => \$out, type => 'ttl');
$exporter->add($input->[0]);
$exporter->commit;
note $out;
=cut

done_testing;
