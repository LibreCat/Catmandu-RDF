# NAME

Catmandu::RDF - Modules for handling RDF data within the Catmandu framework

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-RDF.svg)](https://travis-ci.org/LibreCat/Catmandu-RDF)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-RDF/badge.svg)](https://coveralls.io/r/LibreCat/Catmandu-RDF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-RDF.png)](http://cpants.cpanauthors.org/dist/Catmandu-RDF)

# SYNOPSIS

Command line client `catmandu`:

    catmandu convert RDF --url http://dx.doi.org/10.2474/trol.7.147
                         --fix 'aref_query(dct_title,title)' to YAML

    catmandu convert RDF --file rdfdump.ttl to RDF --type turtle

    # For big file the only efficient option to convert RDF is by
    # transforming the input stream into triples and writing to NTriples
    # in the output
    catmandu convert convert RDF --triples 1 --type ttl to RDF --type NTriples < rdfdump.ttl

See documentation of modules for more examples.

# DESCRIPTION

Catmandu::RDF contains modules for handling RDF data within the [Catmandu](https://metacpan.org/pod/Catmandu)
framework. RDF data is encoded/decoded in [aREF](http://gbv.github.io/aREF/) as
implemented with [RDF::aREF](https://metacpan.org/pod/RDF::aREF). Please keep in mind that RDF is a graph-based
data structuring format with specialized technologies such as SPARQL and triple
stores.  Using Catmandu::RDF to transform RDF to RDF (e.g. conversion from one
RDF serialization to another) is possible but probably less performant than
decent RDF tools. Catmandu::RDF, however, is more conventient to convert
between RDF and  other data formats.

# AVAILABLE MODULES

- [Catmandu::Exporter::RDF](https://metacpan.org/pod/Catmandu::Exporter::RDF)

    Serialize RDF data (as RDF/XML, RDF/JSON, Turtle, NTriples, RDFa...)

- [Catmandu::Importer::RDF](https://metacpan.org/pod/Catmandu::Importer::RDF)

    Parse RDF data (RDF/XML, RDF/JSON, Turtle, NTriples...) or import from a SPARQL
    endpoint

- [Catmandu::Fix::aref\_query](https://metacpan.org/pod/Catmandu::Fix::aref_query)

    Copy values of RDF data in aREF format to a new field

# SEE ALSO

This module is based on [Catmandu](https://metacpan.org/pod/Catmandu), [RDF::aREF](https://metacpan.org/pod/RDF::aREF), [RDF::Trine](https://metacpan.org/pod/RDF::Trine), and
[RDF::NS](https://metacpan.org/pod/RDF::NS).

# COPYRIGHT AND LICENSE

Copyright Jakob Voß, 2014-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

Jakob Voß, Patrick Hochstenbach
