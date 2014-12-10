package Catmandu::Importer::RDF;

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::aREF;
use RDF::aREF::Encoder;
use RDF::NS;

our $VERSION = '0.19';

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
        RDF::aREF::Encoder->new( ns => (($ns // 1) ? $ns : { }) );
    }
);

has triples => (
    is      => 'ro',
);

sub generator {
    my ($self) =@_;
    sub {
        state $stream = $self->_rdf_stream;
        return unless $stream;

        my $aref;

        if ($self->triples) {
            if (my $triple = $stream->next) {
                # TODO: move to RDF::aREF
                my $subject = $triple->subject->is_resource 
                            ? $triple->subject->uri_value 
                            : $triple->subject->sse; # blank
                return {
                    _id => $triple->subject->uri_value,
                    $self->encoder->predicate($triple->predicate->uri_value),
                    $self->encoder->object($triple->object)
                };
            } else {
                return ($stream = undef);
            }
        } else {

            $stream = $stream->as_hashref;
            # TODO if size = 1 use _id => $key
            # TODO: include namespace mappings if requested
            while (my ($s,$ps) = each %$stream) {
                foreach my $p (keys %$ps) {
                    my $predicate = $self->encoder->predicate($p);
                   $stream->{$s}->{$predicate} = [
                        map { $self->encoder->object($_) } @{$stream->{$s}->{$p}} 
                    ]; 
                    delete $stream->{$s}->{$p} if $predicate ne $p;
                }
            }
            $aref = $stream;
            $stream = undef;

            if ($self->url) {
                $aref->{_url} = $self->url;
            }

            return $aref;
        }
    };
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

In Perl code:

    use Catmandu::Importer::RDF;
    my $url = "http://dx.doi.org/10.2474/trol.7.147";
    my $rdf = Catmandu::Importer::RDF->new( url => $url )->first;

=head1 DESCRIPTION

This L<Catmandu::Importer> can be use to import RDF data from URLs, files or
input streams.  Importing from RDF stores or via SPARQL is not supported yet. 

By default an RDF graph is imported as single item in aREF format (see
L<RDF::aREF>).

=head1 CONFIGURATION

=over

=item file

=item fh

=item encoding

=item fix

Default configuration options of L<Catmandu::Importer>. 

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

Import each RDF triple as one aREF predicate map, if enabled.

=back

=head1 METHODS

See L<Catmandu::Importer>.

=head1 SEE ALSO

L<RDF::Trine::Store>, L<RDF::Trine::Parser>

=encoding utf8

=cut
