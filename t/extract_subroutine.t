#!/usr/bin/perl

use strict;
use Test::More;
use Test::Differences;

use Devel::Refactor;

extract_correct('newSub', "print 'foo';", "newSub ();\n",
q{sub newSub {
	print 'foo';
}});

extract_correct('newSub', 'print $foo;', "newSub (\$foo);\n",
q{sub newSub {
	my ($foo) = @_;
	print $foo;
}});

extract_correct('newSub', 'my $foo = 1;', "my \$foo = newSub ();\n",
q{sub newSub {
	my $foo = 1;
	return $foo;
}});

extract_correct('newSub', '(', "newSub ();\n", 
q{sub newSub {
	( #<--- syntax error near "(
}});

extract_correct('newSub', "\$foo{1} = 2;\n\%foo = (1 => 2);", "newSub (\\\%foo);\n",
q{sub newSub {
	my ($foo) = @_;
	$foo->{1} = 2;
	%$foo = (1 => 2);
}});

extract_correct('newSub', "\$foo[0] = 1;\n\@foo = (1);", "newSub (\\\@foo);\n",
q{sub newSub {
	my ($foo) = @_;
	$foo->[0] = 1;
	@$foo = (1);
}});

done_testing();

sub extract_correct {
	my ($name, $code, $expected_call, $expected_code) = @_;
	my $refactory = Devel::Refactor->new();
	my ($new_sub_call, $new_code) = $refactory->extract_subroutine($name, $code, 1);
	is($new_sub_call, $expected_call);
	eq_or_diff($new_code, $expected_code);
}
