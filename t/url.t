use strict;
use Test::More;
use Catmandu -all;

if ($ENV{RELEASE_TESTING}) {
    my $uri = "http://data.uni-muenster.de/context/cris/organization/4863";
    my $importer = importer('RDF', url => $uri, type => 'turtle');
    my $aref = $importer->first;
    my @name = sort @{$aref->{$uri}->{foaf_name}};
    is $name[0], "University of M\x{fc}nster\@en", 'Unicode from url';
} else {
    plan skip_all => 'release test';
}    

done_testing;
