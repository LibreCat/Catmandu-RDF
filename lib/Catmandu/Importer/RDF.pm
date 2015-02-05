package Catmandu::Importer::RDF;

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::Trine::Store::SPARQL;
use RDF::aREF;
use RDF::aREF::Encoder;
use RDF::NS;
use Catmandu::RDF::Fragments;
use Data::Dumper;

our $VERSION = '0.22';

with 'Catmandu::RDF';
with 'Catmandu::Importer';

has url => (
    is => 'ro'
);

has base => (
    is      => 'ro', 
    lazy    => 1, 
    builder => sub {
        defined $_[0]->file ? "file://".$_[0] : "http://example.org/";
    }
);

has encoder => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $ns = $_[0]->ns;
        RDF::aREF::Encoder->new( 
            ns => (($ns // 1) ? $ns : { }),
            subject_map => !$_[0]->predicate_map,
        );
    }
);

has sparql => (
    is      => 'ro',
);

has ldf => (
    is      => 'ro',
);

has predicate_map => (
    is      => 'ro',
);

has triples => (
    is      => 'ro',
);

sub generator {
    my ($self) = @_;

    if ($self->ldf) {
        return $self->ldf_generator;
    }
    elsif ($self->sparql) {
        return $self->sparql_generator;
    }
    else {
        return $self->rdf_generator;
    }
}

sub ldf_generator {
    my ($self) = @_;

    my $ldf = Catmandu::RDF::Fragments->new( url => $self->url );

    sub {
        state $iterator = $ldf->get_statements;

        return undef unless $iterator; 

        state $stream = $iterator->();

        return undef unless $stream;

        my $aref = {};

        if ($self->triples) {
            # Create a stream from the current model...
            state $rdf_stream = $stream->as_stream;

            # Keep reading triples from the current stream...
            if (my $triple = $rdf_stream->next) {
                $aref = $self->encoder->triple(
                            $triple->subject,
                            $triple->predicate,
                            $triple->object
                );
            } else {
                return ($stream = undef);
            }

            # Until the stream is empty and we need to fill a new stream
            unless ($rdf_stream->peek) {
                $stream = $iterator->();
                $rdf_stream = $stream->as_stream if defined $stream;
            }
        }
        else {
            $self->encoder->add_hashref( $stream->as_hashref, $aref );

            if ($self->url) {
                $aref->{_url} = $self->url;
            }

            $stream = $iterator->();
        }

        return $aref;
    };
}

sub sparql_generator {
    my ($self) = @_;

    warn "--triples not active for sparql queries" if ($self->triples);

    sub {
        state $stream = $self->_sparql_stream;
        if (my $row = $stream->next) {
            if (ref $row eq 'RDF::Trine::VariableBindings') {
                my $ref = {};

                for (keys %$row) {
                    my $val = $row->{$_};

                    $ref->{$_} = $self->encoder->object($val);
                }
                return $ref;
            }
            else {
                die "Expected a RDF::Trine::VariableBindings but got a " . ref($row);
            }
        }
        else {
            return ($stream = undef);
        }
    };
}

sub rdf_generator {
    my ($self) = @_;
    sub {
        state $stream = $self->_rdf_stream;
        return unless $stream;

        my $aref = { };
        if ($self->triples) {
            if (my $triple = $stream->next) {
                $aref = $self->encoder->triple(
                        $triple->subject,
                        $triple->predicate,
                        $triple->object
                );
            } else {
                return ($stream = undef);
            }
        } else {
            # TODO: include namespace mappings if requested
            $self->encoder->add_hashref( $stream->as_hashref, $aref );

            if ($self->url) {
                $aref->{_url} = $self->url;
            }

            $stream = undef;
        }

        if ($self->url) {
            # RDF::Trine::Parser parses data from URL to UTF-8
            # but we want internal character sequences
            _utf8_decode($aref);
        }

        return $aref;
    };
}

sub _utf8_decode {
    if (ref $_[0] eq 'HASH') {
        # FIXME: UTF-8 in property values
        foreach (values %{$_[0]}) {
            ref($_) ? _utf8_decode($_) : utf8::decode($_);
        }
    } else {
        foreach (@{$_[0]}) {
            ref($_) ? _utf8_decode($_) : utf8::decode($_);
        }
    }
}

sub _sparql_stream {
    my ($self) = @_;

    die "need an url" unless $self->url;

    $self->log->info("parsing: " . $self->sparql);

    my $store = RDF::Trine::Store::SPARQL->new($self->url);

    unless ($store) {
        $self->log->error("failed to connect to " . $self->url);
        return undef;
    }

    my $iterator = $store->get_sparql($self->sparql);

    unless ($iterator) {
        $self->log->error("failed to execute " . $self->sparql . " at " . $self->url);
        return undef;
    }
}

sub _rdf_stream {
    my ($self) = @_;

    my $model  = RDF::Trine::Model->new;
    my $parser = $self->type 
               ? RDF::Trine::Parser->new( $self->type ) : 'RDF::Trine::Parser';

    if ($self->url) {
        $parser->parse_url_into_model( $self->url, $model );
    } else {
        my $from_scalar = (ref $self->file // '') eq 'SCALAR';
        if (!$self->type and $self->file and !$from_scalar) {
            $parser = $parser->guess_parser_by_filename($self->file);
        }
        if ($from_scalar) {
            $parser->parse_into_model( $self->base, ${$self->file}, $model );
        } else {
            $parser->parse_file_into_model( $self->base, $self->file // $self->fh, $model );
        }
    }
    
    return $model->as_stream;
}

1;
__END__

=head1 NAME

Catmandu::Importer::RDF - parse RDF data

=head1 SYNOPSIS

Command line client C<catmandu>:

    catmandu convert RDF --url http://d-nb.info/gnd/4151473-7 to YAML

    catmandu convert RDF --file rdfdump.ttl to JSON

    # Support for SPARQL
    catmandu convert RDF \
      --url http://dbpedia.org/sparql \
      --sparql "SELECT ?film WHERE { ?film <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:French_films> }"

    # Support for Linked Data Fragments
    catmandu convert RDF \
      --url http://fragments.dbpedia.org/2014/en \
      --ldf 1


In Perl code:

    use Catmandu::Importer::RDF;
    my $url = "http://dx.doi.org/10.2474/trol.7.147";
    my $rdf = Catmandu::Importer::RDF->new( url => $url )->first;

=head1 DESCRIPTION

This L<Catmandu::Importer> can be use to import RDF data from URLs, files or
input streams.  Importing from RDF stores is not supported yet. 

By default an RDF graph is imported as single item in aREF format (see
L<RDF::aREF>).

=head1 CONFIGURATION

=over

=item url

URL to retrieve RDF from.

=item type

RDF serialization type (e.g. C<ttl> for RDF/Turtle).

=item base

Base URL. By default derived from the URL or file name.

=item ns

Use default namespace prefixes as provided by L<RDF::NS> to abbreviate
predicate and datatype URIs. Set to C<0> to disable abbreviating URIs.
Set to a specific date to get stable namespace prefix mappings.

=item triples

Import each RDF triple as one aREF subject map (default) or predicate map
(option C<predicate_map>), if enabled.

=item predicate_map

Import RDF as aREF predicate map, if possible.

=item file

=item fh

=item encoding

=item fix

Default configuration options of L<Catmandu::Importer>. 

=item sparql

The SPARQL query to be executed on the URL endpoint (currectly only SELECT is supported)

=item ldf

The endpoint at the endpoint is a Linked Data fragment server (See: http://linkeddatafragments.org/)

=back

=head1 METHODS

See L<Catmandu::Importer>.

=head1 SEE ALSO

L<RDF::Trine::Store>, L<RDF::Trine::Parser> , L<Catmandu::RDF::Fragments>

=encoding utf8

=cut