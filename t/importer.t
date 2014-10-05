use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Importer::RDF'; }
require_ok $pkg;

my ($importer, $input);

SKIP: {
    my $importer = $pkg->new(file => 't/example.ttl', ns => 0);
    isa_ok $importer, $pkg;

    skip "", 1; # FIXME
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
}

foreach my $file (qw(t/example.ttl t/example.rdf)) {
    $importer = $pkg->new(file => $file, ns => 1);
    $input = $importer->to_array;

    is_deeply $input, [ {
         'http://example.org' => {
            a         => [ 'rdfs_Resource' ],
            dc_title  => [ 'BAR@' ],
            dc_extent => [ '42^xs_integer' ],
            'http://example.org/foo' => [ 'bar@en' ],
         },
       }
    ], "default namespace prefixes ($file)";
}

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
