package Catmandu::Exporter::RDF;

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Serializer;
use RDF::Trine::Model;
use RDF::aREF;

our $VERSION = '0.19';

with 'Catmandu::RDF';
with 'Catmandu::Exporter';

# internal attributes
has decoder => (
    is => 'ro',
    lazy => 1, 
    builder => sub {
        RDF::aREF::Decoder->new( 
            ns => $_[0]->ns // ($_[0]->ns eq 0 ? { } : RDF::NS->new),
            callback => $_[0]->model 
        );
    }
);

has serializer => (
    is => 'ro', 
    lazy => 1, 
    builder => sub {
        # TODO: base_uri and namespaces
        RDF::Trine::Serializer->new($_[0]->type // 'RDFXML')
    }
);

has model => (
    is => 'ro', 
    lazy => 1, 
    builder => sub { RDF::Trine::Model->new }
);

sub add {
    my ($self, $aref) = @_;
    $self->decoder->decode($aref);
}

sub commit {
    my ($self) = @_;
    $self->model->end_bulk_ops;
    $self->serializer->serialize_model_to_file( $self->fh, $self->model );
}

=head1 NAME

Catmandu::Exporter::RDF - serialize RDF data

=head1 SYNOPSIS

    use Catmandu::Exporter::RDF;

    my $exporter = Catmandu::Exporter::RDF->new(
        file => 'export.rdf',
        type => 'XML',
        fix  => 'rdf.fix'
    );

    $exporter->add( $aref ); # pass RDF data in aREF encoding

    $exporter->commit;

=head1 DESCRIPTION

This L<Catmandu::Exporter> exports RDF data in different RDF serializations.

=head1 CONFIGURATION

=over

=item file

=item fh

=item encoding

=item fix

Default configuration options of L<Catmandu::Exporter>.  The option C<fix> is
supported as derived from L<Catmandu::Fixable>. For every C<add> or for every
item in C<add_many> the given fixes will be applied first.

=item type

A serialization form can be set with option C<type>. The option C<type> must
refer to a subclass name of L<RDF::Trine::Serializer>, for instance C<Turtle>
for RDF/Turtle with L<RDF::Trine::Serializer::Turtle>. The first letter is
transformed uppercase, so C<< format => 'turtle' >> will work as well. In
addition there are aliases C<ttl> for C<Turtle>, C<n3> for C<Notation3>, C<xml>
and C<XML> for C<RDFXML>, C<json> for C<RDFJSON>.

=item ns

The option C<ns> can refer to an instance of or to a constructor argument of
L<RDF::NS>. Use a fixed date, such as "C<20130816>" to make sure your URI
namespace prefixes are stable.

=back

=head1 METHODS

See also L<Catmandu::Exporter>.

=head2 add( ... )

RDF data is added given in B<another RDF Encoding Form (aREF)> as 
implemented with L<RDF::aREF> and defined at L<http://github.com/gbv/aref>.

=head2 count

Returns the number of times C<add> has been called. In contrast to other
Catmandu exporters, this does not reflect the number of exporter records
because RDF data is always merged to one RDF graph.

=head2 uri( $uri )

Expand and abbreviated with L<RDF::NS>. For instance "C<dc:title>" is expanded
to "C<http://purl.org/dc/elements/1.1/title>".

=cut

=head1 SEE ALSO

Serialization is based on L<RDF::Trine::Serializer>.

=encoding utf8

=cut

1;
