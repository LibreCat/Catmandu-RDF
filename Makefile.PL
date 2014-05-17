
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Modules for handling RDF data within the Catmandu framework",
  "AUTHOR" => "Jakob Vo\x{df}",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catmandu-RDF",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catmandu::RDF",
  "PREREQ_PM" => {
    "Catmandu" => "0.7",
    "RDF::NS" => 20130816,
    "RDF::Trine" => "1.0",
    "RDF::aREF" => "0.09"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.14",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Catmandu" => "0.7",
  "RDF::NS" => 20130816,
  "RDF::Trine" => "1.0",
  "RDF::aREF" => "0.09"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



