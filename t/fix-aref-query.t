use strict;
use warnings;
use Test::More;
use Catmandu ':all';

use_ok 'Catmandu::Fix::aref_query';

my $fixer = Catmandu::Fix::aref_query->new(
    field => 'title',
    query => 'dc_title'
);

my $rdf = importer('RDF', file => 't/example.ttl')->first;
($rdf->{_uri}) = keys $rdf;

$fixer->fix( $rdf );
delete $rdf->{ $rdf->{_uri} };

is_deeply $rdf, {
    '_uri' => 'http://example.org',
    title => 'BAR'
}, 'simple RDF fix';

done_testing;
