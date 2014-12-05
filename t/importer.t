use strict;
use warnings;
use Test::More;
use Catmandu -all;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Importer::RDF'; }
require_ok $pkg;
isa_ok $pkg->new, $pkg;

my $aref = importer('YAML', file => 't/example.yml')->first;

is_deeply importer('RDF', ns => 0, file => 't/example.ttl')->first, {
     'http://example.org' => {
        a => [ '<http://www.w3.org/2000/01/rdf-schema#Resource>' ],
        'http://example.org/foo' => [ "b\x{e4}r\@en" ],
        'http://purl.org/dc/elements/1.1/title' => [ "B\x{c4}R@" ],
        'http://purl.org/dc/elements/1.1/extent' => [ '42^<http://www.w3.org/2001/XMLSchema#integer>' ],
     },
   }, 'disable namespace prefixes';

foreach my $file (qw(t/example.ttl t/example.rdf)) {
    is_deeply importer('RDF', file => $file, ns => 1)->first,
              $aref, "default namespace prefixes ($file)";
}

{
    use utf8;
    my $ttl = '<http://example.org> <http://example.org/foo> "bär"@en .';
    my $importer = importer('RDF', type => 'turtle', file => \$ttl);    $aref = $importer->first;
    $aref = $importer->first;
    is_deeply $aref->{'http://example.org'}->{'http://example.org/foo'},
        [ 'bär@en' ], 'import from scalar with Unicode';
}

done_testing;
