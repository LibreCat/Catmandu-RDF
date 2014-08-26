package Catmandu::Importer::RDF;
#ABSTRACT: retrieve RDF data
our $VERSION = '0.15'; #VERSION

use namespace::clean;
use Catmandu::Sane;
use Moo;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::aREF;

with 'Catmandu::RDF';
with 'Catmandu::Importer';

has url => (is => 'ro');

has base => (
    is      => 'ro', 
    lazy    => 1, 
    builder => sub {
        defined $_[0]->file ? "file://".$_[0] : "http://example.org/";
    }
);

# TODO: move to RDF::aREF
sub rdfjson2aref {
    my ($object) = @_;
    if ($object->{type} eq 'literal') {
        my $value = $object->{value};
        if ($object->{lang}) {
            return $value.'@'.$object->{lang};
        } elsif ($object->{datatype}) {
            return "$value^<".$object->{datatype}.">";
        } else {
            return "$value@";
        }
    } elsif ($object->{type} eq 'bnode') {
        return $object->{value};
    } else {
        return "<" . $object->{value} . ">";
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
        while (my ($s,$ps) = each %$stream) {
            foreach my $p (keys %$ps) {
                $stream->{$s}->{$p} = [ map { rdfjson2aref($_) } @{$stream->{$s}->{$p}} ]; 
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

Catmandu::Importer::RDF - retrieve RDF data

=head1 VERSION

version 0.15

=head1 DESCRIPTION

B<This module is experimental!>

This L<Catmandu::Importer> can be use to import RDF data from URLs, files or
input streams.  Importing from RDF stores or via SPARQL is not supported yet. 

=head1 CONFIGURATION

=over

=item file

=item fh

=item url

=item type

=item base

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
