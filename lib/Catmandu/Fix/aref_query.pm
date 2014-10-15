package Catmandu::Fix::aref_query;

use Catmandu::Sane;
use Moo;
use RDF::aREF::Query;

has query => (
    is => 'ro',
    coerce => sub { 
        RDF::aREF::Query->new( query => $_[0] ) 
        # TODO: ns
    }
);
has field => (is => 'ro');

sub fix {
    my ($self, $data) = @_;

    my $field = $self->field;
    my $origin = $data->{_uri} // $data->{_url};
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

Catmandu::Fix::aref_query

=cut
