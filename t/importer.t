use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Importer::RDF'; }
require_ok $pkg;

my $importer = $pkg->new(file => 't/example.ttl');
isa_ok $importer, $pkg;

my $input = $importer->to_array;
is_deeply $input, [
   {
     'http://example.org' => {
        'http://example.org/foo' => [ 'bar@en' ],
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' 
            => [ '<http://www.w3.org/2000/01/rdf-schema#Resource>' ]
     }
   }
 ];

done_testing;
