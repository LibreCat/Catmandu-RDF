package Catmandu::Fix::aref_query;

use Catmandu::Sane;
use Moo;
use RDF::aREF::Query;
use Catmandu::Fix::Has;

our $VERSION = '0.23';

has query => (
    is => 'ro',
    coerce => sub { RDF::aREF::Query->new( query => $_[0] ) } # TODO: ns
);
has field => (
    is => 'ro',
);
has subject => (
    is => 'ro',
);

around 'BUILDARGS', sub {
    my $orig = shift;
    my $self = shift;

    if (@_ == 3) {
        $orig->($self, subject => $_[0], query => $_[1], field => $_[2] );
    } elsif (@_ == 2) {
        $orig->($self, query => $_[0], field => $_[1] );
    } else {
        $orig->($self, @_);
    }
};


sub fix {
    my ($self, $data) = @_;

    my $field = $self->field;
    my $origin = $self->subject // $data->{_uri} // $data->{_url};

    my @values = $self->query->apply( $data, $origin );

    if (@values) {
        if (defined $data->{$field}) {
            if (ref $data->{$field}) {
                push @{$data->{$field}}, @values;
            } else {
                $data->{$field} = [ $data->{$field}, @values ];
            }
        } else {
            $data->{$field} = @values > 1 ? \@values : $values[0];
        }
    }

    $data;
}

1;
__END__

=head1 NAME

Catmandu::Fix::aref_query - copy values of RDF in aREF to a new field

=head1 SYNOPSIS

    aref_query( dc_title => title )
    aref_query( query => 'dc_title', field => 'title' )
    aref_query( 'http://example.org/subject', dc_title => title )

=cut
