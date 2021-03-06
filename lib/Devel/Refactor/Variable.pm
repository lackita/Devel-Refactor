package Devel::Refactor::Variable;
use strict;
use warnings;
no warnings 'uninitialized';

use Moose;

has variable_name => (is => 'ro');
has hint => (is => 'ro');

sub name {
	my ($self) = @_;
	return substr($self->variable_name(), 1);
}

sub converted_name {
	my ($self) = @_;
	my $name = $self->variable_name();
	if ( $self->type() eq 'hash' ) {
		$name =~ s/\$/\%/;
	}
	elsif ( $self->type() eq 'array' ) {
		$name =~ s/\$/\@/;
	}
	return $name;
}

sub escaped_name {
	my ($self) = @_;
	if ($self->type() eq 'scalar') {
		return $self->converted_name();
	}
	else {
		return '\\' . $self->converted_name();
	}
}

sub scalar_name {
	my ($self) = @_;
	return '$' . substr($self->converted_name(), 1);
}

sub prefix {
	my ($self) = @_;
	if ($self->type() eq 'hash') {
		return '%';
	}
	elsif ($self->type() eq 'array') {
		return '@';
	}
	else {
		return '$';
	}
}

sub type {
	my ($self) = @_;
	if ( $self->variable_name() =~ /^\%/ || $self->hint() =~ /^{/ ) {
		return 'hash';
	} elsif ( $self->variable_name() =~ /^\@/ || $self->hint() =~ /^\[/ ) {
		return 'array';
	} else {
		return 'scalar';
	}
}

sub is_local_to {
	my ($self, $code_snippet) = @_;

	my $name = $self->converted_name();
	return $code_snippet =~ /\s*my\s*(\([^)]*?)?\Q$name\E([^)]*?\))?/;
}

sub is_iterator_in {
	my ($self, $code_snippet) = @_;
	my $name = $self->converted_name();
	return $self->type() eq 'scalar' && $code_snippet =~ /(?:for|foreach)\s+my\s*\Q$name\E\s*\(/;
}

sub referenced_in {
	my ($self, $code_snippet) = @_;
	my $name = $self->variable_name();
	return $code_snippet =~ /$name/;
}

1;
