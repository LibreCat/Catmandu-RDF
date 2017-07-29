package Catmandu::Importer::RDF;

use open ':std', ':encoding(utf8)';
use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::Trine::Store::SPARQL;
use RDF::Trine::Store::LDF;
use RDF::Trine::Store;
use RDF::Query;
use RDF::LDF;
use RDF::aREF;
use RDF::aREF::Encoder;
use RDF::NS;
use IO::Pipe;
use JSON;
use LWP::UserAgent::CHICaching;

our $VERSION = '0.31';

with 'Catmandu::RDF';
with 'Catmandu::Importer';

has url => (
    is => 'ro'
);

has base => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        defined $_[0]->file ? "file://".$_[0]->file : "http://example.org/";
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
    lazy    => 1,
    trigger  => sub {
        my ($sparql, $ns) = ($_[1], $_[0]->ns);
        $sparql = do { local (@ARGV,$/) = $sparql; <> } if $sparql =~ /^\S+$/ && -r $sparql;
        my %prefix;
        # guess requires prefixes (don't override existing). Don't mind false positives
        $prefix{$_} = 1 for ($sparql =~ /\s([a-z][a-z0-0_-]*):/mig);
        delete $prefix{$_} for ($sparql =~ /PREFIX\s+([^:]+):/mg);
        $_[0]->{sparql} = join "\n", (map { $ns->SPARQL($_) } keys %prefix), $sparql;
    }
);

has sparql_result => (
    is      => 'ro',
    default => sub { 'simple' }
);

has predicate_map => (
    is      => 'ro',
);

has triples => (
    is      => 'ro',
);

has cache => (
    is      => 'ro',
    default => sub { 0 }
);

has cache_options => (
    is      => 'ro',
    default => sub { +{
        driver => 'Memory',
        global => 1 ,
        max_size => 1024*1024
    } }
);

sub BUILD {
    my ($self) = @_;

    if ($self->cache) {
        my $options = $self->cache_options // {};
        my $cache = CHI->new( %$options );
        my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);
        RDF::Trine->default_useragent($ua);
    }
}

sub generator {
    my ($self) = @_;

    if ($self->sparql) {
        return $self->sparql_generator;
    } else {
        return $self->rdf_generator;
    }
}

sub sparql_generator {
    my ($self) = @_;

    warn "--triples not active for sparql queries" if ($self->triples);
    warn "--predicate_map not active for sparql queries" if ($self->predicate_map);

    my $encoder = RDF::aREF::Encoder->new( ns => {} ); # never return qnames

    sub {
        state $stream = $self->_sparql_stream;
        if (defined($stream) && defined(my $row = $stream->next)) {
            if (ref $row eq 'RDF::Query::VariableBindings' || ref $row eq 'RDF::Trine::VariableBindings') {
                my $ref = {};
                for (keys %$row) {
                    my $val = $row->{$_};
                    $ref->{$_} = $self->sparql_result eq 'aref'
                               ? $encoder->object($val) : do { # TODO: clean up
                                  if ( $val->is_resource ) {
                                     $val->uri_value;
                                  } elsif ( $val->is_literal) {
                                     $val->literal_value;
                                  } else {
                                     $val->as_string
                                  }
                               };
                }
                return $ref;
            } else {
                die "Expected a RDF::Query::VariableBindings or RDF::Trine::VariableBindings but got a " . ref($row);
            }
        } else {
            return ($stream = undef);
        }
    };
}

sub rdf_generator {
    my ($self) = @_;
    sub {
        state $stream = $self->_hashref_stream;
        return unless $stream;

        my $aref = { };

        if ($self->triples) {
            if (my $hashref = $stream->()) {
                $self->encoder->add_hashref($hashref, $aref);
            }
            else {
                return ($stream = undef);
            }
        }
        else {
            # TODO: include namespace mappings if requested
            while (my $hashref = $stream->()) {
              $self->encoder->add_hashref(
                  $hashref,
                  $aref
              );
            }

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

    my $store;

    # Check if this server is an LDF server
    my $ldf_client = RDF::LDF->new(url => $self->url);

    if ($ldf_client->is_fragment_server) {
        $store = RDF::Trine::Store->new_with_config({
                    storetype => 'LDF',
                    url => $self->url
        });
    }
    else {
        $store = RDF::Trine::Store->new_with_config({
                    storetype => 'SPARQL',
                    url => $self->url
        });
    }

    unless ($store) {
        $self->log->error("failed to connect to " . $self->url);
        return;
    }

    my $model =  RDF::Trine::Model->new($store);

    my $rdf_query = RDF::Query->new($self->sparql);

    unless ($rdf_query) {
        $self->log->error("failed to parse " . $self->sparql);
        return;
    }

    my $iterator = $rdf_query->execute($model);

    unless ($iterator) {
        $self->log->error("failed to execute " . $self->sparql . " at " . $self->url);
        return;
    }
}

sub _hashref_stream {
  my ($self) = @_;

  my $pipe = IO::Pipe->new();

  if (my $pid = fork()) {
    # parent
    $pipe->reader();

    binmode($pipe,':encoding(UTF-8)');

    return sub {
      state $line = <$pipe>;

      return decode_json($line) if defined($line);

      waitpid($pid,0);

      return undef;
    };
  }
  else {
    # child
    $pipe->writer();

    binmode($pipe,':encoding(UTF-8)');

    my $parser = $self->type
               ? RDF::Trine::Parser->new( $self->type ) : 'RDF::Trine::Parser';

    my $handler = sub {
        my $triple = shift;

        my $subject   = $triple->subject->value;
        my $predicate = $triple->predicate->value;
        my $value     = $triple->object->is_literal ?
                            $triple->object->literal_value :
                            $triple->object->is_blank ?
                              $triple->object->value :
                              $triple->object->uri_value;
        my $type      = lc $triple->object->type;
        my $lang      = $triple->object->is_literal ? $triple->object->literal_value_language : undef;
        my $datatype  = $triple->object->is_literal ? $triple->object->literal_datatype : undef;

        my $hashref = {};

        $hashref->{$subject}->{$predicate}->[0]->{type}     = $type;
        $hashref->{$subject}->{$predicate}->[0]->{datatype} = $datatype if $datatype;
        $hashref->{$subject}->{$predicate}->[0]->{lang}     = $lang if $lang;
        $hashref->{$subject}->{$predicate}->[0]->{value}    = $value;

        print $pipe encode_json($hashref) , "\n";
    };

    if ($self->url) {
        $parser->parse_url( $self->url, $handler);
    }
    else {
        my $from_scalar = (ref $self->file // '') eq 'SCALAR';

        if (!$self->type and $self->file and !$from_scalar) {
            $parser = $parser->guess_parser_by_filename($self->file)->new;
        }

        if ($from_scalar) {
            $parser->parse( $self->base, ${$self->file}, $handler );
        }
        else {
            $parser->parse_file( $self->base, $self->file // $self->fh, $handler );
        }
    }

    exit(0);
  }
}


1;

__END__

=head1 NAME

Catmandu::Importer::RDF - parse RDF data

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert RDF --url http://d-nb.info/gnd/4151473-7 to YAML

  catmandu convert RDF --type ttl --file rdfdump.ttl to JSON

  # For big input files it will be faster not to build a big hash in memory
  # bit to return each triple fragment
  catmandu convert RDF --type ttl --triples 1 --file rdfdump.ttl to JSON

  # Transform back into NTriples
  catmandu convert RDF --type ttl --triples 1 --file rdfdump.ttl to RDF --type NTriples

  # Query a SPARQL endpoint
  catmandu convert RDF --url http://dbpedia.org/sparql
                       --sparql "SELECT ?film WHERE { ?film dct:subject <http://dbpedia.org/resource/Category:French_films> }"

  catmandu convert RDF --url http://example.org/sparql --sparql query.rq

  # Query a Linked Data Fragment endpoint
  catmandu convert RDF --url http://fragments.dbpedia.org/2014/en
                       --sparql "SELECT ?film WHERE { ?film dct:subject <http://dbpedia.org/resource/Category:French_films> }"

In Perl code:

    use Catmandu::Importer::RDF;
    my $url = "http://dx.doi.org/10.2474/trol.7.147";
    my $rdf = Catmandu::Importer::RDF->new( url => $url )->first;

=head1 DESCRIPTION

This L<Catmandu::Importer> can be use to import RDF data from URLs, files or
input streams, SPARQL endpoints, and Linked Data Fragment endpoints.

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

The SPARQL query to be executed on the URL endpoint (currectly only SELECT is
supported).  The query can be supplied as string or as filename. The importer
tries to automatically add missing PREFIX statements from the default namespace
prefixes.

=item sparql_result

Encoding of SPARQL result values. With C<aref>, query results are encoded in
aREF format, with URIs in C<E<lt>> and C<E<gt>> (no qNames) and literal nodes
appended by C<@> and optional language code. By default (value C<simple>), all
RDF nodes are simplfied to their literal form.

=item cache

Set to a true value to cache repeated URL responses in a L<CHI> based backend.

=item cache_options

Provide the L<CHI> based options for caching result sets. By default a memory store of
1MB size is used. This is equal to:

    Catamandu::Importer::RDF->new( ...,
        cache => 1,
        cache_options => {
            driver => 'Memory',
            global => 1,
            max_size => 1024*1024
        });

=back

=head1 METHODS

See L<Catmandu::Importer>.

=head1 SEE ALSO

L<RDF::Trine::Store>, L<RDF::Trine::Parser>

=encoding utf8

=cut
