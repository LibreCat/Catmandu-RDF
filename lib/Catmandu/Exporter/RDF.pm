package Catmandu::Exporter::RDF;
#ABSTRACT: serialize RDF data
#VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Serializer;
use RDF::NS;

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

    my $rdf = $self->_expand_rdf($data);
    #use Data::Dumper; say STDERR Dumper($rdf);
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

sub _blank {
    my ($self) = @_;
    return '_:b'.++$self->{_blank_id};
}

sub _expand_object {
    my ($self,$obj) = @_;

    # RDF::Trine allows: plain literal or /^_:/ or /^[a-z0-9._\+-]{1,12}:\S+$/i or /^(.*)\@([a-z]{2})$/)
    return $obj if !ref $obj;

    my ($rdf, $bnode) = { };

    if ($obj->{'@id'}) {
        $rdf = { type => 'uri', value => $obj->{'@id'} };
    } elsif ($obj->{'@value'}) {
        $rdf = { type => 'literal', value => $obj->{'@value'} };
        $rdf->{datatype} = $self->uri($obj->{'@type'}) if defined $obj->{'@type'}; 
        #TODO #@language
    } else {
        $rdf->{type}  = 'bnode';
        $rdf->{value} = $self->_blank();

        for (keys %$obj) { # TODO: recurse via _expand_rdf
            next if /^@/;

            my $b_predicate = $self->uri($_);
            my $b_object    = $self->_expand_object($obj->{$_});

            push @{ $bnode->{$b_predicate} }, $b_object;
        }
        $bnode = { $rdf->{value} => $bnode } if $bnode;
    }

    # TODO @type
    # TODO: _:xx allowed in RDF:NS?

    return ($rdf, $bnode);
}

sub _expand_rdf {
    my ($self,$data) = @_;

    return $data unless $data->{'@id'};
    my $subject = $data->{'@id'};

    my @triples;

    my $statements = {};
    my $triples = { $subject => $statements };

    foreach my $p (keys %$data) {
        next if $p eq '@id';
        my ($predicate, $object) = ($p, $data->{$p});

        # TODO: disallow http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml (better in RDF::NS)
        if ($predicate =~ /^([a-z][a-z0-9]*)[:_]/ and $1 ne 'http') {
            $predicate = $self->uri($predicate);
        }

        my ($o, $t) = $self->_expand_object($object);
        push @{ $statements->{$predicate} }, $o;

        if ($t) { # additional triples
            $triples->{$_} = $t->{$_} for keys %$t;
        }
    }

    return $triples;
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

The option C<ns> can refer to an instance of or to a constructor argument of
L<RDF::NS>. Use a fixed date, such as '20130816' to make sure your URI
namespace prefixes are stable.

=head2 add

RDF data can be added as used by L<RDF::Trine::Model/as_hashref> in form of
hash references.  A simplified form of JSON-LD will be supported as well.

=head2 count

Always returns 1 because there is always one RDF graph in a RDF document.

=head2 uri

Used to expands an URI with L<RDF::NS>: for instance C<dc:title> is expanded to
<http://purl.org/dc/elements/1.1/title>.

=cut

=head1 SEE ALSO

L<Catmandu::Exporter>, L<RDF::Trine::Serializer>

=cut

1;
