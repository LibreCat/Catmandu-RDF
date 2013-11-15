use strict;
use warnings;
use Test::More;

use RDF::aREF;

my $a = RDF::aREF->new;

my @tests = (
    '@' => { value => '', type => 'literal'  },
    '' => { value => '', type => 'literal'  },
    '^xsd:string' => { value => '', type => 'literal'  },
    '^^xsd:string' => { value => '', type => 'literal'  },
    '^^<http://www.w3.org/2001/XMLSchema#string>' => { value => '', type => 'literal'  },
    '@^xsd:string' => { value => '@', type => 'literal'  },
    '@@' => { value => '@', type => 'literal'  },
    'alice@' => { value => 'alice', type => 'literal'  },
    'alice@en' => { value => 'alice', lang => 'en', type => 'literal'  },
    'alice@example.com' => { value => 'alice@example.com', type => 'literal'  },
    '123' => { value => '123', type => 'literal'  },
    '123^xsd:integer' => { value => '123', type => 'literal', datatype => 'http://www.w3.org/2001/XMLSchema#integer' },
    '123^^xsd:integer' => { value => '123', type => 'literal', datatype => 'http://www.w3.org/2001/XMLSchema#integer' },
    '123^^<xsd:integer>' => { value => '123', type => 'literal', datatype => 'xsd:integer' },
    '忍者@ja' => { value => '忍者', lang => 'ja', type => 'literal' },
    'Ninja@en@' => { value => 'Ninja@en', type => 'literal' },
   'foo:bar' => 'unknown prefix in foo:bar',
   'rdf:type' => { value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', type => 'uri' },
   '<rdf:type>' => { value => 'rdf:type', type => 'uri' },
   'geo:48.2010,16.3695,183' => { type => 'uri', value => 'geo:48.2010,16.3695,183' },
   'geo:Point' => { type => 'uri', value => 'http://www.w3.org/2003/01/geo/wgs84_pos#Point' },
);

while (defined (my $string = shift(@tests))) {
    if (ref (my $expect = shift @tests)) {
        is_deeply $a->object_to_rdfjson($string), $expect, "\"$string\"";
    } else {
        eval { $a->object_to_rdfjson($string) };
        is $@, "$expect\n", $expect;
    }
};

is_deeply $a->to_rdfjson({ 
    _id => 'http://me.markus-lanthaler.com/',
    'schema:name' => 'Markus Lanthaler'    
}),
 {
   'http://me.markus-lanthaler.com/' => {
     'http://schema.org/name' => [{
       'type' => 'literal',
       'value' => 'Markus Lanthaler'
     }]
   }
 }, 'Example 11 from JSON-LD';

is_deeply $a->to_rdfjson({ 
    _id => 'http://me.markus-lanthaler.com/',
    'a' => ['schema:Restaurant','schema:Brewery'],
}),
 {
   'http://me.markus-lanthaler.com/' => {
     'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [
       {
         'type' => 'uri',
         'value' => 'http://schema.org/Restaurant'
       },
       {
         'type' => 'uri',
         'value' => 'http://schema.org/Brewery'
       }
     ]
   }
 }, 'Example 14 from JSON-LD';

is_deeply $a->to_rdfjson({ 
    _id => "http://example.org/posts#TripToWestVirginia",
    a => "http://schema.org/BlogPosting",
    dct_modified => "2010-05-29T14:17:39+02:00^xsd:dateTime"
}),
 {
  'http://example.org/posts#TripToWestVirginia' => {
    'http://purl.org/dc/terms/modified' => [{
      'datatype' => 'http://www.w3.org/2001/XMLSchema#dateTime',
      'type'     => 'literal',
      'value'    => '2010-05-29T14:17:39+02:00'
    }],
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
      'type'  => 'uri',
      'value' => 'http://schema.org/BlogPosting'
    }]
  }
}, 'Example 23 from JSON-LD';

is_deeply $a->to_rdfjson({ 
    '_id' => 'http://example.org/',
    'http://example.org/predicate' => { '_id' => 'http://example.com/object' },
}),
 {
   'http://example.org/' => {
     'http://example.org/predicate' => [{
       'type' => 'uri',
       'value' => 'http://example.com/object'
     }]
   }
 };

my $r = $a->to_rdfjson({
    '_id' => 'http://example.org/',
    'http://example.org/predicate' => { },
});
my $bnode = delete($r->{'http://example.org/'}{'http://example.org/predicate'}->[0]->{value});
like $bnode, qr{^_:([a-z0-9]+)$}i, 'bnode';
is_deeply $r, {
   'http://example.org/' => {
     'http://example.org/predicate' => [{
       'type' => 'bnode',
     }]
   }
};

my $data = { # example copied from RDF::Trine::Model
  "http://example.com/subject1" => {
    "http://example.com/predicate1" => [
        'Foo@en',
        "Bar^<http://example.com/datatype1>" 
    ],
  },
  "_:bnode1" => {
    "http://example.com/predicate2" => [
      "http://example.com/object2",
    ],
    "http://example.com/predicate2" => [
      "_:bnode3",
    ],
  },
};

#note explain $a->to_rdfjson($data);
done_testing;
