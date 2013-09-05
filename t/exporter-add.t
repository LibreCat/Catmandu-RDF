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

    is $file, $result, $_[0];
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

done_testing;

__END__

# Support a subset of JSON-LD
# TODO: test
{
    'geo:location' => {
        'geo:lat' => '...',
        'geo:long' => '...',
    },
}

set_field('@id','http://example.org/subject1');
set_field('dc:title','Example');
set_field('dc:modified.@value',"2010-05-29T14:17:39+02:00");
set_field('dc:modified.@type','xsd:dateTime');
