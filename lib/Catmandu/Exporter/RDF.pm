package Catmandu::Exporter::RDF;
#ABSTRACT: serialize RDF data
#VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Serializer;

with 'Catmandu::Exporter';

has type => (is => 'ro', default => sub { 'RDFXML' });
has serializer => (is => 'ro', lazy => 1, builder => '_build_serializer' );
has _data => (is => 'rw'); # TODO: 

our %TYPE_ALIAS = (
    Ttl  => 'Turtle',
    N3   => 'Notation3',
    Xml  => 'RDFXML',
    XML  => 'RDFXML',
    Json => 'RDFJSON',
);

sub _build_serializer {
    my ($self) = @_;

    my $type = ucfirst($self->type);
    $type = $TYPE_ALIAS{$type} if $TYPE_ALIAS{$type};

    RDF::Trine::Serializer->new($type); # TODO: base_uri  and  namespaces
}

sub add {
    my ($self, $data) = @_;

    $self->_data(RDF::Trine::Iterator->new()) unless $self->_data;

    # TODO: make performant
    my $model = RDF::Trine::Model->new;

    # TODO: support lazy hashref with RDF::NS etc.
    # e.g. subject in _id:
    $model->add_hashref( $data );

    $self->_data(
        $self->_data->concat( $model->as_stream )
    );

    # $self->commit; # TODO: enable streaming serialization this way?
}

sub commit {
    my ($self) = @_;

    $self->serializer->serialize_iterator_to_file( $self->fh, $self->_data );
}

=head1 SYNOPSIS

    use Catmandu::Exporter::RDF;

    my $exporter = Catmandu::Exporter::RDF->new(
        file => 'export.rdf',
        type => 'XML',
        fix  => 'rdf.fix'
    );

    $exporter->commit;

=head1 DESCRIPTION

=head1 METHODS

=head2 new(file => $file, type => $type, %options)

Create a new Catmandu RDF exporter which serializes into a file or to STDOUT.

A serialization form can be set with option C<type>. The type must be a
subclass name of L<RDF::Trine::Serializer>, for instance C<Turtle> for
RDF/Turtle with L<RDF::Trine::Serializer::Turtle>. The first letter is
transformed uppercase, so C<< format => 'turtle' >> will work as well. In
addition there are aliases C<ttl> for C<Turtle>, C<n3> for C<Notation3>, C<xml>
and C<XML> for C<RDFXML>, C<json> for C<RDFJSON>.

The option C<fix> is supported as derived from L<Catmandu::Fixable>. For every
C<add> or for every item in C<add_many> the given fixes will be applied first.

=head2 count

Always returns 1 because there is always one RDF graph in a RDF document.

TODO: better return the number of unique RDF subjects?

=cut

=head1 SEE ALSO

L<Catmandu::Exporter>, L<RDF::Trine::Serializer>

=cut

1;
