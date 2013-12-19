#!/usr/bin/perl

use strict;

use Devel::Refactor::File;
use File::Copy;
use File::Slurp;
use File::Temp;
use Test::Differences;
use Test::More;

my $file = Devel::Refactor::File->new(contents => q{print 'foo';});

method_extracted_correctly('no_variables', 0, 12);
method_extracted_correctly('no_variables_within_sub', 14, 12);
method_extracted_correctly('extracted_after_current_call', 14, 12);
# method_extracted_correctly('variable_not_needed_outside_extraction', 0, 16);

done_testing();

sub method_extracted_correctly {
	my ($name, $start, $length) = @_;
	my $file = File::Temp->new();
	copy(_path_for_fixture_file($name), $file->filename());
	my $file_converter = Devel::Refactor::File->new(
		path => $file->filename(),
	);

	$file_converter->extract_method('newSub', $start, $length);
	eq_or_diff(
		scalar(read_file($file_converter->path())),
		scalar(read_file(_path_for_fixture_file("${name}_refactored"))),
	);
}

sub _path_for_fixture_file {
	my ($name) = @_;
	return "t/fixtures/extract_method/$name.pl";
}
