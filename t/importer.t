use strict;
use warnings;
use Test::More;
use Catmandu -all;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::Importer::RDF'; }
require_ok $pkg;
isa_ok $pkg->new, $pkg;

my $aref = importer('YAML', file => 't/example.yml')->first;
my $expect = {
    'http://example.org' => {
        a => '<http://www.w3.org/2000/01/rdf-schema#Resource>',
        'http://example.org/foo' => "b\x{e4}r\@en",
        'http://purl.org/dc/elements/1.1/title' => "B\x{c4}R@",
        'http://purl.org/dc/elements/1.1/extent' => 
            '42^<http://www.w3.org/2001/XMLSchema#integer>',
     }
};

is_deeply importer('RDF', ns => 0, file => 't/example.ttl')->first, 
          $expect, 'disable namespace prefixes';

foreach my $file (qw(t/example.ttl t/example.rdf)) {
    is_deeply importer('RDF', file => $file, ns => 1)->first,
              $aref, "default namespace prefixes ($file)";
}

{
    use utf8;
    my $ttl = '<http://example.org> <http://example.org/foo> "bär"@en .';
    my $importer = importer('RDF', type => 'turtle', file => \$ttl);    
    my $aref = $importer->first;
    is_deeply $aref->{'http://example.org'}->{'http://example.org/foo'},
        'bär@en', 'import from scalar with Unicode';
}

{
    my $importer = importer('RDF', file => 't/example.ttl', triples => 1, predicate_map => 1);
    my $aref = $importer->to_array;
    is_deeply [ 
        sort { 
            my (undef,$x) = sort keys %$a; 
            my (undef,$y) = sort keys %$b; 
            $x cmp $y 
        } @$aref 
    ], [
       { _id => 'http://example.org', a => 'rdfs_Resource' },
       { _id => 'http://example.org', dc_extent => '42^xs_integer' },
       { _id => 'http://example.org', dc_title => "B\x{c4}R@" },
       { _id => 'http://example.org', 'http://example.org/foo' => "b\x{e4}r\@en" }
    ], 'import triples';

    my $nt = "";
    my $exporter = exporter('RDF', type => 'ntriples', file => \$nt);
    $exporter->add_many($aref);
    $exporter->commit;
    $importer = importer('RDF', type => 'ntriples', file => \$nt, ns => 0);
    is_deeply $importer->first, $expect, 'round-trip export-import-export';
}

SKIP: {
  skip "networking requires RELEASE_TESTING set", 1
    unless $ENV{'RELEASE_TESTING'};

    {
        my $sparql   =<<END;
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    SELECT * WHERE { ?book dc:title ?title . }
END
        my $importer = importer('RDF', url => 'http://sparql.org/books/sparql' , sparql => $sparql);
        ok $importer , 'got a SPARQL importer';

        my $ref = $importer->first;
        ok $ref->{title} , 'got a title';
        ok $ref->{book} , 'got a book';
    }
}

done_testing;
