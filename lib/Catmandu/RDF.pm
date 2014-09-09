package Catmandu::RDF;
#ABSTRACT: Modules for handling RDF data within the Catmandu framework
#VERSION

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_instance);
use Moo::Role;
use RDF::NS;

our %TYPE_ALIAS = (
    Ttl  => 'Turtle',
    N3   => 'Notation3',
    Xml  => 'RDFXML',
    XML  => 'RDFXML',
    Json => 'RDFJSON',
);

# todo use 'file' to guess type
has type => (
    is => 'ro', 
    coerce => sub { my $t = ucfirst($_[0]); $TYPE_ALIAS{$t} // $t },
);

has ns => (
    is => 'ro', 
    default => sub { RDF::NS->new },
    coerce => sub {
        return $_[0] if is_instance($_[0],'RDF::NS');
        return if !$_[0];
        return RDF::NS->new($_[0]);
    },
    handles => ['uri'],
);

=head1 DESCRIPTION

Catmandu::RDF contains modules for handling RDF data within the L<Catmandu>
framework. This release is in an early state of development. Feedback and
contributions are very welcome at L<https://github.com/nichtich/Catmandu-RDF>!

=head1 AVAILABLE MODULES

=over 4

=item L<Catmandu::Exporter::RDF>

Serialize RDF data (as RDF/XML, RDF/JSON, Turtle, NTriples, RDFa...).
RDF data must be provided in B<another RDF Encoding Form (aREF)> as 
implemented with L<RDF::aREF>.

=item L<Catmandu::Importer::RDF>

Parse RDF data (RDF/XML, RDF/JSON, Turtle, NTriples...).

=back

=head1 SUGGESTED MODULES

The following modules have not been implemented yet. Please contribute or
comment if you miss them!

=over 4

=item C<Catmandu::Importer::SPARQL>

Import RDF data from a SPARQL endpoint.

=item C<Catmandu::Exporter::SPARUL> or C<Catmandu::Exporter::SPARQL>

Export RDF data with SPARQL/Update.

=item C<Catmandu::Exporter::RDFPatch>

Export RDF with HTTP PATCH.

=back

=encoding utf8

=head1 SEE ALSO

This module is based on L<Catmandu>, L<RDF::aREF>, L<RDF::Trine>, and
L<RDF::NS>.

=cut

1;
