package Catmandu::Importer::RDF;

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::aREF;
use RDF::aREF::Encoder;
use RDF::NS;

our $VERSION = '0.16';

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
        RDF::aREF::Encoder->new( ns => $_[0]->ns );
    }
);

sub generator {
    my ($self) =@_;
    sub {
        state $stream = $self->_rdf_stream;
        return unless $stream;

        my $aref;
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

        if ($self->url) {
            $aref->{_url} = $self->url;
        }

        $stream = undef;

        return $aref;
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
        if (defined $self->file and !$self->type) { 
            $parser = $parser->guess_parser_by_filename($self->file);
        }
        $parser->parse_file_into_model( $self->base, $self->file // $self->fh, $model );
    }
    
    return $model->as_stream;
}

1;
__END__

=head1 NAME

Catmandu::Importer::RDF - parse RDF data

=head1 SYNOPSIS

Command line client C<catmandu>:

    catmandu convert RDF --url http://d-nb.info/1001703464 to YAML
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

=back

=head1 METHODS

See L<Catmandu::Importer>.

=head1 SEE ALSO

L<RDF::Trine::Store>, L<RDF::Trine::Parsers>

=encoding utf8

=cut
