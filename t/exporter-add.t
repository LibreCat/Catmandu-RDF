use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::RDF;

sub check_add(@) {
    my $options = shift;
    my $data    = shift;
    my $result  = shift;

    my $file = "";
    my $exporter = Catmandu::Exporter::RDF->new(file => \$file, %$options);

    $exporter->add($data);
    $exporter->commit;

    if (ref $result) {
        $result->($file);
    } else {
        is $file, $result, $_[0];
    }
}


check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    'dc:title' => 'Subject',
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/title> \"Subject\" .\n",
    'expand predicate URI';

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    'dc:title' => { '@value' => 'Subject' },
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/title> \"Subject\" .\n",
    'literal object';

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    'dct:extent' => { '@value' => '42', '@type' => 'xsd:integer' },
} => "<http://example.org/> <http://purl.org/dc/terms/extent> 42 .\n",
    'literal object with datatype';

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    'http://example.org/predicate' => { '@id' => 'http://example.com/object' },
} => "<http://example.org/> <http://example.org/predicate> <http://example.com/object> .\n",
    'uri object';

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    'http://example.org/predicate' => { },
} => "<http://example.org/> <http://example.org/predicate> _:b1 .\n",
    'blank node object';

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://www.gbv.de/',
    'geo:location' => {
        'geo:lat' => '9.93492',
        'geo:long' => '51.5393710',
    } 
} => sub {
    my $ttl = shift;
    ok $ttl =~ qr{_:b1 <http://www.w3.org/2003/01/geo/wgs84_pos\#lat> "9.93492"} 
    && $ttl =~ qr{<http://www.w3.org/2003/01/geo/wgs84_pos\#long> "51.5393710"}
    && $ttl =~ qr{<http://www.gbv.de/> <http://www.w3.org/2003/01/geo/wgs84_pos\#location> _:b1},
        'nested RDF';
};

check_add { type => 'ttl', ns => '20130816' }, {
    '@id' => 'http://example.org/',
    a => 'foaf:Organization',
} => "<http://example.org/> a <http://xmlns.com/foaf/0.1/Organization> .\n",
    '"a" for rdf:type';

## fixes

check_add { type => 'ttl', ns => '20130816', 
    fix => ["move_field('_id','\@id')","prepend('\@id','http://example.org/');"]
}, {
    '_id' => 123,
    'dc:title' => 'Foo',
} => "<http://example.org/123> <http://purl.org/dc/elements/1.1/title> \"Foo\" .\n",
    'fix subject URI';

check_add { type => 'ttl', ns => '20130816', 
    fix => [
        "move_field('dc:extent','dc:extent.\@value');",
        "add_field('dc:extent.\@type','xsd:integer');"
    ]
}, {
    '@id' => 'http://example.org/',
    'dc:extent' => '42',
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/extent> 42 .\n",
    'fix predicate';

done_testing;
