package Devel::Refactor::File;
use strict;
use warnings;

use File::Basename;
use File::Slurp;
use Devel::Refactor;
use Devel::Refactor::ExtractMethod;
use Moose;
use Perl::Tidy;

has path => (is => 'rw');
has contents => (
	is => 'rw',
	lazy => 1,
	default => sub {
		my ($self) = @_;
		return scalar(read_file($self->path()));
	},
);

sub extract_method {
	my ($self, $name, $start, $length) = @_;

	my $refactory = Devel::Refactor->new();
	my $extractor = Devel::Refactor::ExtractMethod->new(
		sub_name => $name,
		code_snippet => substr($self->contents(), $start, $length),
		syntax_check => 1,
	);

	my $new_contents = join("",
		$self->_before_call($start),
		$extractor->sub_call(),
		$self->_after_call($start, $length, $extractor->new_method()),
	);

	my $tidied_contents;
	Perl::Tidy::perltidy(
		source => \$new_contents,
		destination => \$tidied_contents,
	);

	$self->contents($tidied_contents);

	$self->_write_back_to_file();
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
		return "$before_sub$sub\n\n$after_sub";
	}
	else {
		return "$after_call\n$sub\n";
	}
}

sub _write_back_to_file {
	my ($self) = @_;
	my $path = $self->path();
	my $patch = dirname($path) . "/refactor.patch";
	open PATCH, '|-', "diff $path - > $patch";
	print PATCH $self->contents();
	close PATCH;
}

1;
