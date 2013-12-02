package Catmandu::RDF;
# ABSTRACT: Modules for handling RDF data within the Catmandu framework
# VERSION

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

=back

=head1 SUGGESTED MODULES

The following modules have not been implemented yet. Please contribute or
comment if you miss them!

=over 4

=item C<Catmandu::Importer::RDF>

Import serialized RDF data (RDF/XML, RDF/JSON, Turtle, NTriples, RDFa...).

=item C<Catmandu::Importer::SPARQL>

Import RDF data from a SPARQL endpoint.

=item C<Catmandu::Exporter::SPARUL> or C<Catmandu::Exporter::SPARQL>

Export RDF data with SPARQL/Update.

=item C<Catmandu::Exporter::RDFPatch>

Export RDF with HTTP PATCH.

=back

=encoding utf8

=head1 SEE ALSO

L<Catmandu>, L<RDF::aREF>, L<RDF::Trine>, L<RDF::NS>

=cut

1;
