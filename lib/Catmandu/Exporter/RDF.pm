package Catmandu::Exporter::RDF;
# ABSTRACT: serialize RDF data
our $VERSION = '0.14'; # VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Serializer;
use RDF::Trine::Model;
use RDF::NS;
use RDF::aREF;

with 'Catmandu::Exporter';

our %TYPE_ALIAS = (
    Ttl  => 'Turtle',
    N3   => 'Notation3',
    Xml  => 'RDFXML',
    XML  => 'RDFXML',
    Json => 'RDFJSON',
);

has type => (
    is => 'ro', 
    default => sub { 'RDFXML' }, 
    coerce => sub { my $t = ucfirst($_[0]); $TYPE_ALIAS{$t} // $t },
);

has ns => (
    is => 'ro', 
    default => sub { RDF::NS->new() },
    coerce => sub {
        (!ref $_[0] or ref $_[0] ne 'RDF::NS') ? RDF::NS->new(@_) : $_[0];
    },
    handles => ['uri'],
);

# internal attributes

has decoder => (
    is => 'ro',
    lazy => 1, 
    builder => sub {
        RDF::aREF::Decoder->new( ns => $_[0]->ns, callback => $_[0]->model );
    }
);

has serializer => (
    is => 'ro', 
    lazy => 1, 
    builder => sub {
        # TODO: base_uri and namespaces
        RDF::Trine::Serializer->new($_[0]->type)
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



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Exporter::RDF - serialize RDF data

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use Catmandu::Exporter::RDF;

    my $exporter = Catmandu::Exporter::RDF->new(
        file => 'export.rdf',
        type => 'XML',
        fix  => 'rdf.fix'
    );

    $exporter->add( $aref ); # pass RDF data in aREF encoding

    $exporter->commit;

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

RDF data is added given in B<another RDF Encoding Form (aREF)> as 
implemented with L<RDF::aREF> and defined at L<http://github.com/gbv/aref>.

=head2 count

Always returns 1 or 0 (there is only one RDF graph in a RDF document).

=head2 uri( $uri )

Expand and abbreviated with L<RDF::NS>. For instance "C<dc:title>" is expanded
to "C<http://purl.org/dc/elements/1.1/title>".

=head1 SEE ALSO

L<Catmandu::Exporter>, L<RDF::Trine::Serializer>

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
