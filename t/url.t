use strict;
use Test::More;
use Catmandu -all;

if ($ENV{RELEASE_TESTING}) {
    my $uri = "http://www.w3.org/TR/turtle/examples/example1.ttl";
    my $importer = importer('RDF', url => $uri, type => 'turtle');
    my $aref = $importer->first;
    is $aref->{'http://www.w3.org/TR/rdf-syntax-grammar'}->{dc_title},
       'RDF/XML Syntax Specification (Revised)@', 'Import from URL';
} else {
    plan skip_all => 'release test';
}    

done_testing;
