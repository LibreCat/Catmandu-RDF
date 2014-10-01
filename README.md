# NAME

Catmandu::RDF - Modules for handling RDF data within the Catmandu framework

# STATUS

[![Build Status](https://travis-ci.org/gbv/Catmandu-RDF.png)](https://travis-ci.org/gbv/Catmandu-RDF)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-RDF/badge.png?branch=devel)](https://coveralls.io/r/gbv/Catmandu-RDF?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-RDF.png)](http://cpants.cpanauthors.org/dist/Catmandu-RDF)

# DESCRIPTION

Catmandu::RDF contains modules for handling RDF data within the [Catmandu](https://metacpan.org/pod/Catmandu)
framework. This release is in an early state of development. Feedback and
contributions are very welcome at [https://github.com/nichtich/Catmandu-RDF](https://github.com/nichtich/Catmandu-RDF)!

# AVAILABLE MODULES

- [Catmandu::Exporter::RDF](https://metacpan.org/pod/Catmandu::Exporter::RDF)

    Serialize RDF data (as RDF/XML, RDF/JSON, Turtle, NTriples, RDFa...).
    RDF data must be provided in **another RDF Encoding Form (aREF)** as 
    implemented with [RDF::aREF](https://metacpan.org/pod/RDF::aREF).

- [Catmandu::Importer::RDF](https://metacpan.org/pod/Catmandu::Importer::RDF)

    Parse RDF data (RDF/XML, RDF/JSON, Turtle, NTriples...).

# SUGGESTED MODULES

The following modules have not been implemented yet. Please contribute or
comment if you miss them!

- `Catmandu::Importer::SPARQL`

    Import RDF data from a SPARQL endpoint.

- `Catmandu::Exporter::SPARUL` or `Catmandu::Exporter::SPARQL`

    Export RDF data with SPARQL/Update.

- `Catmandu::Exporter::RDFPatch`

    Export RDF with HTTP PATCH.

# SEE ALSO

This module is based on [Catmandu](https://metacpan.org/pod/Catmandu), [RDF::aREF](https://metacpan.org/pod/RDF::aREF), [RDF::Trine](https://metacpan.org/pod/RDF::Trine), and
[RDF::NS](https://metacpan.org/pod/RDF::NS).

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
