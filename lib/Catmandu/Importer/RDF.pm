package Catmandu::Importer::RDF;
#ABSTRACT: parse RDF data
our $VERSION = '0.16'; #VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::aREF;
use RDF::NS;

with 'Catmandu::RDF';
with 'Catmandu::Importer';

has url => (
    is => 'ro'
);

has 'sn' => (
    is => 'ro',
    lazy    => 1, 
    builder => sub {
        $_[0]->ns ? $_[0]->ns->REVERSE : undef
    }
);

has base => (
    is      => 'ro', 
    lazy    => 1, 
    builder => sub {
        defined $_[0]->file ? "file://".$_[0] : "http://example.org/";
    }
);

# TODO: move to RDF::aREF
sub uri2aref {
    my ($self, $uri, $sep) = @_;

    return 'a' if $uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

    if ($self->sn) {
        my @qname = $self->sn->qname($uri);
        return join($sep,@qname) if @qname;
    }

    return $uri;
}
# TODO: move to RDF::aREF
sub rdfjson2aref {
    my ($self, $object) = @_;
    if ($object->{type} eq 'literal') {
        my $value = $object->{value};
        if ($object->{lang}) {
            return $value.'@'.$object->{lang};
        } elsif ($object->{datatype}) {
            my $dt = $self->uri2aref($object->{datatype},':');
            $dt = "<$dt>" if $dt eq $object->{datatype};
            return "$value^$dt";
        } else {
            return "$value@";
        }
    } elsif ($object->{type} eq 'bnode') {
        return $object->{value};
    } else {
        my $obj = $self->uri2aref($object->{value},':');
        return ($obj eq $object->{value} ? "<$obj>" : $obj);
    }
}

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
                my $predicate = $self->uri2aref($p,'_');
               $stream->{$s}->{$predicate} = [
                    map { $self->rdfjson2aref($_) } @{$stream->{$s}->{$p}} 
                ]; 
                delete $stream->{$s}->{$p} if $predicate ne $p;
            }
        }
        $aref = $stream;
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

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Importer::RDF - parse RDF data

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  catmandu convert RDF --file rdfdump.ttl to YAML

=head1 SYNOPSIS

  catmandu convert RDF --url http://d-nb.info/1001703464 to YAML

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

=head1 SEE ALSO

L<RDF::Trine::Store>, L<RDF::Trine::Parsers>

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
