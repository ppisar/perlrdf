# RDF::Query::Algebra::Clear
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::Algebra::Clear - Algebra class for CLEAR operations

=head1 VERSION

This document describes RDF::Query::Algebra::Clear version 2.900_01, released 30 January 2010.

=cut

package RDF::Query::Algebra::Clear;

use strict;
use warnings;
no warnings 'redefine';
use base qw(RDF::Query::Algebra);

use Data::Dumper;
use Log::Log4perl;
use Scalar::Util qw(refaddr);
use Carp qw(carp croak confess);
use Scalar::Util qw(blessed reftype refaddr);
use Time::HiRes qw(gettimeofday tv_interval);
use RDF::Trine::Iterator qw(smap sgrep swatch);

######################################################################

our ($VERSION);
my %TRIPLE_LABELS;
my @node_methods	= qw(subject predicate object);
BEGIN {
	$VERSION	= '2.900_01';
}

######################################################################

=head1 METHODS

=over 4

=cut

=item C<new ( $graph )>

Returns a new CLEAR structure.

=cut

sub new {
	my $class	= shift;
	my $graph	= shift;
	unless ($graph) {
		$graph	= RDF::Trine::Node::Nil->new;
	}
	return bless([$graph], $class);
}

=item C<< construct_args >>

Returns a list of arguments that, passed to this class' constructor,
will produce a clone of this algebra pattern.

=cut

sub construct_args {
	my $self	= shift;
	return ($self->graph);
}

=item C<< as_sparql >>

Returns the SPARQL string for this alegbra expression.

=cut

sub as_sparql {
	my $self	= shift;
	my $context	= shift;
	my $indent	= shift;
	
	my $graph	= $self->graph;
	my $string	= ($graph->is_nil)
				? 'CLEAR GRAPH DEFAULT'
				: sprintf( "CLEAR GRAPH <%s>", $graph->uri_value );
	return $string;
}

=item C<< sse >>

Returns the SSE string for this alegbra expression.

=cut

sub sse {
	my $self	= shift;
	my $context	= shift;
	my $indent	= shift;
	
	my $graph	= $self->graph;
	my $string	= ($graph->is_nil)
				? '(clear default)'
				: sprintf( "(clear <%s>)", $graph->uri_value );
	return $string;
}

=item C<< referenced_blanks >>

Returns a list of the blank node names used in this algebra expression.

=cut

sub referenced_blanks {
	my $self	= shift;
	return;
}

=item C<< referenced_variables >>

=cut

sub referenced_variables {
	my $self	= shift;
	return;
}

=item C<< graph >>

=cut

sub graph {
	my $self	= shift;
	return $self->[0];
}

1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut
