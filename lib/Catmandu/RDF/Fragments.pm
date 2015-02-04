package Catmandu::RDF::Fragments::Iterator;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;

with 'Catmandu::Iterable';

has sub => (
    is => 'ro' ,
    required => 1
); 

sub generator {
	shift->sub;
}

package Catmandu::RDF::Fragments;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use RDF::NS;
use RDF::Trine;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;

our $VERSION = '0.01';

with 'Catmandu::Logger';

has url => (
    is => 'ro' ,
    required => 1
);

has ua => (
	is      => 'ro',
    lazy    => 1,
    builder => sub {
        LWP::UserAgent->new( agent => "Catmandu::RDF::Fragments/$Catmandu::RDF::Fragments::VERSION" );
    }
);

has sn => (
	is     => 'ro' ,
	lazy   => 1,
	builder => sub {
		RDF::NS->new->REVERSE;
	}
);

has pattern => (
	is      => 'ro',
    lazy    => 1,
    builder => 'get_pattern'
);

sub is_fragment_server {
	shift->pattern ? 1 : 0;
}

# Dynamic find out which tripple patterns need to be used to query the fragment server
# Returns a hash:
# {
#   rdf_subject   => <name_of_subject_variable> ,
#   rdf_predicate => <name_of_predicate_variable> ,
#   rdf_object    => <name_of_object_variable>
#   void_uriLookupEndpoint => <endpoint_for_tripple_pattern>
# }
sub get_pattern {
	my ($self) = @_;
	my $url   = $self->url;
	my $model =	$self->get_fragment($url);

	return undef unless defined $model;

	my $info  = $self->_parse_model($model,$url);

	my $pattern;

	return undef unless is_hash_ref($info);

	return undef unless $info->{void_uriLookupEndpoint};

	for (keys %$info) {
		next unless is_hash_ref($info->{$_}) && $info->{$_}->{hydra_property};
		my $property = join "_" , $self->sn->qname($info->{$_}->{hydra_property});
		my $variable = $info->{$_}->{hydra_variable};

		$pattern->{$property} = $variable;
	}

	return undef unless $pattern->{rdf_subject};
	return undef unless $pattern->{rdf_predicate};
	return undef unless $pattern->{rdf_object};

	$pattern->{void_uriLookupEndpoint} = $info->{void_uriLookupEndpoint};

	$pattern;
}

# Given $subject,$predicate,$object return a generator for RDF::Trine::Model-s
sub get_statements {
	my ($self,$subject,$predicate,$object) = @_;

	my $pattern = $self->pattern;

	return undef unless defined $pattern;

	my @param = ();

	push @param , $pattern->{rdf_subject}   . "=" . uri_escape($subject)   if is_string($subject);
	push @param , $pattern->{rdf_predicate} . "=" . uri_escape($predicate) if is_string($predicate);
	push @param , $pattern->{rdf_object}    . "=" . uri_escape($object)    if is_string($object);

	my $url = $self->url;

	if (@param) {
		my $params = join("&",@param);
		$url = $pattern->{void_uriLookupEndpoint};
		$url =~ s/{\?\S+}/?$params/;
	}

	my $sub = sub {
		return unless defined $url;
		my $model =	$self->get_fragment($url);

		return undef unless defined $model;

		my $info  = $self->_parse_model($model,$url);
		$url = $info->{hydra_nextPage};

		$model;
	};

	Catmandu::RDF::Fragments::Iterator->new(sub => $sub);
}

sub get_fragment {
	my ($self,$url) = @_;
	$self->log->debug("fetching: $url");

	my $req = GET $url, Accept => 'text/turtle';

	my $response = $self->ua->request($req);

	if ($response->is_success) {
		$self->parse_string($response->decoded_content);
	}
	else {
		warn Dumper($response);
		Catmandu::Error->throw("$url failed");
	}
}

sub parse_string {
	my ($self,$string) = @_;
    $self->log->debug("parsing: $string");
	my $parser = RDF::Trine::Parser->new('turtle');
	my $model  = RDF::Trine::Model->temporary_model;

	eval {
		$parser->parse_into_model($self->url,$string,$model);
	};

	if ($@) {
		$self->log->error("failed to parse input");
		return undef;
	}

	$model;
}

sub _parse_model {
	my ($self,$model,$this_uri) = @_;

	my $info = {};

	$self->_build_info($model, {
		subject => RDF::Trine::Node::Resource->new($this_uri)
	} , $info);

	for my $predicate (
		'http://www.w3.org/ns/hydra/core#variable' ,
		'http://www.w3.org/ns/hydra/core#property' ,
		'http://www.w3.org/ns/hydra/core#mapping'  ,
		'http://www.w3.org/ns/hydra/core#template' ,
		'http://www.w3.org/ns/hydra/core#membe'    ,
	) {
		$self->_build_info($model, {
			predicate => RDF::Trine::Node::Resource->new($predicate)
		}, $info);
	}

	my $source = $info->{dct_source}->[0] if is_array_ref($info->{dct_source});

	if ($source) {
		$self->_build_info($model, {
			subject => RDF::Trine::Node::Resource->new($source)
		}, $info);
	}

	$info;
}

sub _build_info {
	my ($self, $model, $triple, $info) = @_;
	
	my $iterator = $model->get_statements(
		$triple->{subject},
		$triple->{predicate},
		$triple->{object}
	);

	while (my $triple = $iterator->next) {
		my $subject   = $triple->subject->as_string;
		my $predicate = $triple->predicate->uri_value;
		my $object    = $triple->object->value;

		my $qname = join "_" , $self->sn->qname($predicate);

		if ($qname =~ /^(hydra_variable|hydra_property)$/) {
			my $id= $triple->subject->value;

			$info->{"_$id"}->{$qname} = $object;
		}
		elsif ($qname eq 'hydra_mapping') {
			my $id= $triple->subject->value;

			push @{$info->{"_$id"}->{$qname}} , $object;
		}
		elsif ($qname =~ /^(void|hydra)_/) {
			$info->{$qname} = $object;
		}
		else {
			push @{$info->{$qname}} , $object;
		}
	}

	$info;
}

1;

__END__

=head1 NAME

Catmandu::RDF::Fragments - Linked Data Fragments client

=head1 SYNOPSIS

	use Catmandu::RDF::Fragments;

	my $client = Catmandu::RDF::Fragments->new(url => 'http://fragments.dbpedia.org/2014/en');

	my $iterator = $client->get_statements($subject, $predicate, $object);

	while (my $model = $iterator->generator->()) {
		# $model is a RDF::Trine::Model
	} 

	# or via a Catmandu importer
	use Catmandu;

	my $importer = Catmandu->importer('RDF', url => 'http://fragments.dbpedia.org/2014/en' , ldf => 1);

	$importer->each(sub {
		my $aref = shift;

		# $aref is a RDF::aRef hash
	});

=head1 DESCRIPTION

The Catmandu module is a basic implementation of a Linked Data Fragment client. For details see:
<http://linkeddatafragments.org/>

=head1 CONFIGURATION

=over

=item url

URL to retrieve RDF from.

=back

=head1 METHODS

=over 

=item get_statements($subject,$predicate,$object)

Return a Catmandu::RDF::Fragments::Iterator for every model served by the LDF server.

=back

=head1 SEE ALSO

L<Catmandu::Importer::RDF>, L<RDF::Trine::Model> , L<RDF::aREF>

=head1 AUTHOR

Patrick Hochstenbach

=encoding utf8

=cut