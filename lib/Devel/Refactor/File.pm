package Devel::Refactor::File;
use strict;
use warnings;

use Devel::Refactor;
use Moose;

has contents => (
	is => 'rw',
);

sub extract_method {
	my ($self, $name, $start, $length) = @_;

	my $refactory = Devel::Refactor->new();
	my ($call, $sub) = $refactory->extract_subroutine($name, substr($self->contents(), $start, $length));

	$self->contents(join("",
		$self->_before_call($start),
		$call,
		$self->_after_call($start, $length, $sub),
	));
}

sub _before_call {
	my ($self, $start) = @_;
	return substr($self->contents(), 0, $start);
}

sub _after_call {
	my ($self, $start, $length, $sub) = @_;
	my $after_call = substr($self->contents(), $start + $length);
	$after_call =~ s/^\n//s;
	if (my ($before_sub, $after_sub) = $after_call =~ /^(.*?)(sub.*)$/s) {
		return "$before_sub$sub\n$after_sub";
	}
	else {
		return "$after_call\n$sub";
	}
}

1;
