package RDF::aREF;
#ABSTRACT: Another RDF Encoding Form
our $VERSION = '0.01';

use RDF::NS;

use parent 'Exporter';
#our @EXPORT = qw();

sub new {
    my ($class, %options) = @_;

    bless {
        ns => $options{ns} || RDF::NS->new()
    }, $class;
}
    #use Data::Dumper; say STDERR Dumper($rdf);

=head1 SYNOPSIS

  my $aref = {
     # aREF RDF data
  };

  my $rdfjson = RDF::aREF->new->to_rdfjson( $aref );
  RDF::Trine::Model->add_hashref( $rdfjson );

=cut

# requires Perl 5.12
use v5.12;
use feature 'unicode_strings';

our $nameChar = 'A-Z_a-z\N{U+00C0}-\N{U+00D6}\N{U+00D8}-\N{U+00F6}\N{U+00F8}-\N{U+02FF}\N{U+0370}-\N{U+037D}\N{U+037F}-\N{U+1FFF}\N{U+200C}-\N{U+200D}\N{U+2070}-\N{U+218F}\N{U+2C00}-\N{U+2FEF}\N{U+3001}-\N{U+D7FF}\N{U+F900}-\N{U+FDCF}\N{U+FDF0}-\N{U+FFFD}\N{U+10000}-\N{U+EFFFF}';
our $nameStartChar = $nameChar.'0-9\N{U+00B7}\N{U+0300}\N{U+036F}\N{U+203F}-\N{U+2040}-';
our $prefix = '[a-z]([a-z]|[0-9])*';
our $name   = "[$nameStartChar][$nameChar]*";
our $prefixedName = "$prefix:$name";

# TODO
our $plainIRI = qr{^[a-z][a-z0-9+.-]*:}i;

our $blankNode = qr{^_:([a-z0-9]+)$}i;

# object string
sub object_to_rdfjson {
    my ($self, $string) = @_;

    # absolute IRI enclosed in angle brackets
    if ($string =~ /^<(.+)>$/) {
        my $iri = $1; # TODO: validate IRI
        return { value => $iri, type => 'uri' };

    # blank node
    } elsif ($string =~ $blankNode) {
        return { value => $string, type => "bnode" };

    # prefixedName
    } elsif ($string =~ /^($prefix):($name)$/) {
        return { value => $self->prefixedName($1,$3), type => 'uri' };

    # languageTaggedString
    } elsif ($string =~ s/\@([a-z]{2,8}(-[a-z0-9]{1,8})*)$//) {
        return { value => $string, lang => $1, type => 'literal' };

    # datatypedString
    } elsif ($string =~ /^(.*)\^(($prefix):($name)|<(.+)>)$/) {

        my $value    = $1; 
        my $datatype;

        if (defined $3) {
            $datatype = $self->prefixedName($3,$5);
        } elsif (defined $6) {
            $datatype = $6; # TODO: validate IRI
        }
        
        $value =~ s/\^$//; 

        if ($datatype eq 'http://www.w3.org/2001/XMLSchema#string') {
            return { value => $value, type => 'literal' };
        } else {
            return { value => $value, type => 'literal', datatype => $datatype };
        }

    # explicitString
    } elsif ($string =~ s/\@$//) {
        return { value => $string, type => 'literal' };

    # plainIRI
    } elsif ($string =~ $plainIRI) {
        # TODO: validate syntax according to RFC 3987
        return { value => $string, type => 'uri' };
    }

    # simpleString
    return { value => $string, type => 'literal' };
}

sub prefixedName {
    my ($self, $prefix, $name) = @_;

    my $ns = $self->{ns}->{$prefix}
        or die "unknown prefix in $prefix:$name\n";

    # no IRI validation required with sane prefix definition
    return "$ns$name";
}

sub subject {
    my ($self, $string) = @_;

    my $subject = $string;

    # absolute IRI enclosed in angle brackets
    if ($subject =~ /^<(.+)>$/) {
        $subject = $1;

    # blank node
    } elsif ($subject =~ /^_:([a-zA-Z0-9]+)$/) {
        # $subject = $subject;

    # prefixed name (also with '_')
    } elsif ($subject =~ /^($prefix)[:_]($name)$/) {
        $subject = $self->prefixedName($1,$3);
    } 

    # TODO: should match plainIRI
    
    return $subject;
}

# TODO: implement to_iterator instead
sub to_rdfjson {
    my ($self, $graph) = @_;

    # TODO: _ns

    # property map
    if ($graph->{_id}) {
        my $subject = $self->subject($graph->{_id});    
        return $self->property_map_to_rdfjson( $subject => $graph ),

    # subject map
    } else {
        my $rdfjson = { };
        foreach my $subject ( grep { $_ ne '_ns' } keys %$graph ) {
            my $rdf = $self->property_map_to_rdfjson( 
                $self->subject($subject) => $graph->{$subject}
            );
            # merge (TODO: just return triples)
            foreach (keys %$rdf) {
                $rdfjson->{$_} = $rdf->{$_};
            }
        }
        return $rdfjson;
    }
}

sub property {
    my ($self, $string) = @_;

    # special shortcut 'a'
    if ($string eq 'a') {
        return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

    # absolute IRI enclosed in angle brackets
    } elsif ($string =~ /^<(.+)>$/) {
        $string = $1;

    # prefixed name (also with '_')
    } elsif ($string =~ /^($prefix)[:_]($name)$/) {
        return $self->prefixedName($1,$3);
    }
    
    # TODO: validate IRI
    return $string;
}

sub property_map_to_rdfjson {
    my ($self, $subject, $map) = @_;
    
    my $statements = { };

    my $predicate_map = {
        map {
            my ($object, $stms) = 
                $self->encoded_object_to_rdfjson($map->{$_});

            # TODO: merge instead of replace, also different oid forms
            $statements = $stms if $stms and %$stms;

            ($self->property($_) => $object);
        } grep { $_ ne '_id' and $_ ne '_ns' } keys %$map
    };

    my $rdfjson = %$predicate_map ? { $subject => $predicate_map } : { };

    # Merge
    if (%$statements) {
        # TODO: merge instead replace
        for (keys %$statements) {
            $rdfjson->{$_} = $statements->{$_};
        }
    }
    
    return $rdfjson;
}

use Scalar::Util qw(reftype);

sub encoded_object_to_rdfjson {
    my ($self, $object) = @_;

    my $ref = reftype $object;

    if (!$ref) {
        return [ $self->object_to_rdfjson($object) ];
    } elsif($ref eq 'ARRAY') {
        return [ map { $self->object_to_rdfjson($_); } @$object ];
    } elsif($ref eq 'HASH') {
        my $id = $object->{_id};

        if (!defined $id) {
            $id = $self->blank_id;
        } elsif ($id =~ /^<(.+)>$/) {
            $id = $1;
        } elsif ($id =~ /^($prefix)[:_]($name)$/) {
            $id = $self->prefixedName($1,$3);
        }

        my $obj;
        if ($id =~ $blankNode) {
            $obj = { value => $id, type => "bnode" };
        } elsif ($id =~ $plainIRI) {
            $obj = { value => $id, type => "uri" };
        } else {
            die "expected IRI or blank node, got ".$object->{_id}."\n";
        }

        my $statements = $self->property_map_to_rdfjson( $id => $object );

        return [ $obj ], $statements;

    } else {
        print $object;
        die "encoded object must be a string, list, or predicate map!\n";
    }

}

sub blank_id {
    my ($self) = @_;
    return '_:'.++$self->{blank_counter};
}

1;

=head1 DESCRIPTION

This module implements a parser of Another RDF encoding form (aREF). The module
is shipped with L<Catmandu::RDF> but will be refactored to be published as
independent module on CPAN. As aREF is not finally specified, this module is in
a very early state of development!

=head1 SEE ALSO

aREF is being specified at L<http://github.com/gbv/aref>.

See L<RDF::YAML> for an outdated parser/serializer of a similar RDF encoding in
YAML.

=encoding utf8

=cut
