package Catmandu::Exporter::RDF;
# ABSTRACT: serialize RDF data
# VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Serializer;
use RDF::NS;
use RDF::aRef;

with 'Catmandu::Exporter';

has type => (is => 'ro', default => sub { 'RDFXML' });
has serializer => (is => 'ro', lazy => 1, builder => '_build_serializer' );

# experimental
has _data => (is => 'rw');
has ns => (
    is => 'ro', 
    default => sub { RDF::NS->new() },
    coerce => sub {
        (!ref $_[0] or ref $_[0] ne 'RDF::NS') ? RDF::NS->new(@_) : $_[0];
    },
    handles => ['uri'],
);

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

    # TODO: use iterater of statements instead

    my $rdf = RDF::aRef->new( ns => $self->ns )->to_rdfjson( $data );
    # use Data::Dumper; say Dumper($rdf);
    $model->add_hashref( $rdf );

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

Have a look at the unit tests in C<exporter-add.t> for usage examples!

=head1 METHODS

=head2 new(file => $file, type => $type, %options)

Create a new Catmandu RDF exporter which serializes into a file or to STDOUT.

A serialization form can be set with option C<type>. The option C<type> must
refer to a subclass name of L<RDF::Trine::Serializer>, for instance C<Turtle>
for RDF/Turtle with L<RDF::Trine::Serializer::Turtle>. The first letter is
transformed uppercase, so C<< format => 'turtle' >> will work as well. In
addition there are aliases C<ttl> for C<Turtle>, C<n3> for C<Notation3>, C<xml>
and C<XML> for C<RDFXML>, C<json> for C<RDFJSON>.

The option C<fix> is supported as derived from L<Catmandu::Fixable>. For every
C<add> or for every item in C<add_many> the given fixes will be applied first.

The option C<ns> can refer to an instance of or to a constructor argument of
L<RDF::NS>. Use a fixed date, such as "C<20130816>" to make sure your URI
namespace prefixes are stable.

=head2 add( ... )

RDF data can be added in B<Another RDF encoding form (aRef)> as defined at
L<http://github.com/gbv/aref>. Not all aspects of aRef are supported yet.

=head2 count

Always returns 1 or 0 (there is only one RDF graph in a RDF document).

=head2 uri( $uri )

Expand and abbreviated with L<RDF::NS>. For instance "C<dc:title>" is expanded
to "C<http://purl.org/dc/elements/1.1/title>".

=cut

=head1 SEE ALSO

L<Catmandu::Exporter>, L<RDF::Trine::Serializer>

=encoding utf8

=cut

1;
