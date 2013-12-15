#!/usr/bin/perl

use strict;
use Test::More;
use Test::Differences;

use Devel::Refactor::File;

my $file = Devel::Refactor::File->new(contents => q{print 'foo';});

$file->extract_method('newSub', 0, 12);
eq_or_diff($file->contents(), q{newSub ();

sub newSub {
	print 'foo';
}
});

$file->contents(q{
sub oldSub {
	print 'foo';
}
});
$file->extract_method('newSub', 15, 12);
eq_or_diff($file->contents(), q{
sub oldSub {
	newSub ();
}

sub newSub {
	print 'foo';
}
});

$file->contents(q{
sub oldSub {
	print 'foo';
}

sub otherSub {
	print 'bar';
}
});
$file->extract_method('newSub', 15, 12);
eq_or_diff($file->contents(), q{
sub oldSub {
	newSub ();
}

sub newSub {
	print 'foo';
}

sub otherSub {
	print 'bar';
}
});

done_testing();
