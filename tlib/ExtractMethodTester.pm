package ExtractMethodTester;
use strict;
use warnings;

use Moose;

use Devel::Refactor::ExtractMethod;
use Test::More;
use Test::Differences;

has code => (is => 'rw');
has after_call => (is => 'rw');
has args_hash => (is => 'rw');

sub extractor {
	my ($self) = @_;
	return Devel::Refactor::ExtractMethod->new(
		sub_name => 'newSub',
		code_snippet => $self->code(),
		after_call => $self->after_call(),
		syntax_check => 1,
		args_hash => $self->args_hash(),
	);
}

sub call_is {
	my ($self, $expected_call) = @_;
	is($self->extractor()->sub_call(), $expected_call);
}

sub sub_is {
	my ($self, $expected_sub) = @_;
	eq_or_diff($self->extractor()->new_method(), $expected_sub);
}

1;
