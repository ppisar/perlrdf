# RDF::Query::Plan::Triple
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::Plan::Triple - Executable query plan for Triples.

=head1 METHODS

=over 4

=cut

package RDF::Query::Plan::Triple;

use strict;
use warnings;
use base qw(RDF::Query::Plan);

use Scalar::Util qw(blessed);

use RDF::Query::ExecutionContext;
use RDF::Query::VariableBindings;

=item C<< new ( $triple ) >>

=cut

sub new {
	my $class	= shift;
	my @triple	= @_;
	my $self	= $class->SUPER::new( @triple );
	
	### the next two loops look for repeated variables because some backends
	### (Redland and RDF::Core) can't distinguish a pattern like { ?a ?a ?b }
	### from { ?a ?b ?c }. if we find repeated variables (there can be at most
	### one since there are only three nodes in a triple), we save the positions
	### in the triple that hold the variable, and the code in next() will filter
	### out any results that don't have the same value in those positions.
	###
	### in the first pass, we also set up the mapping that will let us pull out
	### values from the result triples to construct result bindings.
	
	my %var_to_position;
	my @methodmap	= qw(subject predicate object);
	my %counts;
	my $dup_var;
	foreach my $idx (0 .. 2) {
		my $var	= $triple[ $idx ];
		if (blessed($var) and ($var->isa('RDF::Trine::Node::Variable') or $var->isa('RDF::Trine::Node::Blank'))) {
			my $name	= ($var->isa('RDF::Trine::Node::Blank')) ? '__' . $var->blank_identifier : $var->name;
			$var_to_position{ $name }	= $methodmap[ $idx ];
			$counts{ $name }++;
			if ($counts{ $name } >= 2) {
				$dup_var	= $name;
			}
		}
	}
	
	my @positions;
	if (defined($dup_var)) {
		foreach my $idx (0 .. 2) {
			my $var	= $triple[ $idx ];
			if (blessed($var) and ($var->isa('RDF::Trine::Node::Variable') or $var->isa('RDF::Trine::Node::Blank'))) {
				my $name	= ($var->isa('RDF::Trine::Node::Blank')) ? '__' . $var->blank_identifier : $var->name;
				if ($name eq $dup_var) {
					push(@positions, $methodmap[ $idx ]);
				}
			}
		}
	}
	
	$self->[4]{mappings}	= \%var_to_position;
	
	if (@positions) {
		$self->[4]{dups}	= \@positions;
	}
	
	return $self;
}

=item C<< execute ( $execution_context ) >>

=cut

sub execute ($) {
	my $self	= shift;
	my $context	= shift;
	if ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "BGP plan can't be executed while already open";
	}
	my @triple	= @{ $self }[ 1 .. 3 ];
	my $bridge	= $context->model;
	my $iter	= $bridge->get_statements( @triple, $context->query, $context->bound );
	
	if (blessed($iter)) {
		$self->[4]{iter}	= $iter;
		$self->state( $self->OPEN );
	} else {
		warn "no iterator in execute()";
	}
}

=item C<< next >>

=cut

sub next {
	my $self	= shift;
	unless ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "next() cannot be called on an un-open BGP";
	}
	my $iter	= $self->[4]{iter};
	LOOP: while (my $row = $iter->next) {
		if (my $pos = $self->[4]{dups}) {
			my @pos	= @$pos;
			my $first_method	= shift(@pos);
			my $first			= $row->$first_method();
			foreach my $p (@pos) {
				unless ($first->equal( $row->$p() )) {
					next LOOP;
				}
			}
		}
		
		my $binding	= {};
		foreach my $key (keys %{ $self->[4]{mappings} }) {
			my $method	= $self->[4]{mappings}{ $key };
			$binding->{ $key }	= $row->$method();
		}
		return RDF::Query::VariableBindings->new( $binding );
	}
	return;
}

=item C<< close >>

=cut

sub close {
	my $self	= shift;
	unless ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "close() cannot be called on an un-open BGP";
	}
	delete $self->[4]{iter};
	delete $self->[4]{iter};
	$self->SUPER::close();
}

1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut