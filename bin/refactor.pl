#!/usr/bin/perl

use Devel::Refactor::File;

my ($file, $method, $name, $position, $length) = @ARGV;

my $file = Devel::Refactor::File->new(
	path => $file,
);

$file->$method($name, $position, $length);
