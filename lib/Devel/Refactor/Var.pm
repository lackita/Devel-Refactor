package Devel::Refactor::Var;
use strict;
use warnings;
no warnings 'uninitialized';

use Moose;

has name => (is => 'ro');
has hint => (is => 'ro');
has converted_name => (
	is => 'rw',
	lazy => 1,
	default => sub {
		my ($self) = @_;
		my $name = $self->name();
        if ( $self->type() eq 'hash' ) {
            $name =~ s/\$/\%/;
        } elsif ( $self->type() eq 'array' ) {
            $name =~ s/\$/\@/;
		}
		return $name;
	},
);

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
