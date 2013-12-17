package Devel::Refactor::Var;
use strict;
use warnings;
no warnings 'uninitialized';

use Moose;

has name => (is => 'ro');
has hint => (is => 'ro');

sub type {
	my ($self) = @_;
	if ( $self->name() =~ /^\%/ || $self->hint() =~ /^{/ ) {
		return 'hash';
	} elsif ( $self->name() =~ /^\@/ || $self->hint() =~ /^\[/ ) {
		return 'array';
	} else {
		return 'scalar';
	}
}

1;
