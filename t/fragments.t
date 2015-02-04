use strict;
use warnings;
use Test::More;
use Catmandu -all;
use Data::Dumper;

my $pkg;
BEGIN { use_ok $pkg = 'Catmandu::RDF::Fragments'; }
require_ok $pkg;

my $frag1 = $pkg->new(url => 'http://fragments.dbpedia.org/2014/en');

ok $frag1->is_fragment_server , 'http://fragments.dbpedia.org/2014/en is a LDFserver';

my $pattern = $frag1->pattern;

ok $pattern , 'got a tripple pattern';

ok $frag1 , 'got a client';

my $iterator = $frag1->get_statements();

ok $iterator , 'got an iterator on all triples';

$iterator->take(1)->each(sub {
    my $model = shift;
    my $it = $model->get_statements();

    ok $it , 'got an iterator';

    while (my $triple = $it->next) {
        ok $triple , 'got triples';
    }
});

$iterator = $frag1->get_statements("http://dbpedia.org/resource/Arthur_Schopenhauer");

ok $iterator , 'got an iterator on http://dbpedia.org/resource/Arthur_Schopenhauer';

$iterator->take(1)->each(sub {
    my $model = shift;
    my $it = $model->get_statements();

    ok $it , 'got an iterator';

    while (my $triple = $it->next) {
        ok $triple , 'got triples';

        my $subject   = $triple->subject->as_string;
        my $predicate = $triple->predicate->as_string;
        my $object    = $triple->predicate->as_string;

        print "$subject $predicate $object\n";

    }
});

my $frag2 = $pkg->new(url => 'http://biblio.ugent.be/publication/4384199.rdf');

ok ! $frag2->is_fragment_server , 'http://biblio.ugent.be/publication/4384199.rdf is not a LDF server';

my $frag3 = $pkg->new(url => 'http://kasei.us/2009/09/sparql/sd-example.ttl');

ok ! $frag3->is_fragment_server , 'http://kasei.us/2009/09/sparql/sd-example.ttl is not a LDF server';

done_testing;
