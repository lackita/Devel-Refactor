#!/usr/bin/perl

use strict;
use Test::More;
use Test::Differences;

use Devel::Refactor;
use Devel::Refactor::ExtractMethod;

call_is("print 'foo';", "newSub ();\n");
sub_is("print 'foo';",
q{sub newSub {
	print 'foo';
}});

call_is('print $foo;', "newSub (\$foo);\n");
sub_is('print $foo;',
q{sub newSub {
	my ($foo) = @_;
	print $foo;
}});

call_is('my $foo = 1;', "my \$foo = newSub ();\n");
sub_is('my $foo = 1;', 
q{sub newSub {
	my $foo = 1;
	return $foo;
}});

call_is('(', "newSub ();\n",);
sub_is('(',
q{sub newSub {
	( #<--- syntax error near "(
}});

call_is("\$foo{1} = 2;\n\%foo = (1 => 2);", "newSub (\\\%foo);\n");
sub_is("\$foo{1} = 2;\n\%foo = (1 => 2);",
q{sub newSub {
	my ($foo) = @_;
	$foo->{1} = 2;
	%$foo = (1 => 2);
}});

call_is("\$foo[0] = 1;\n\@foo = (1);", "newSub (\\\@foo);\n");
sub_is("\$foo[0] = 1;\n\@foo = (1);",
q{sub newSub {
	my ($foo) = @_;
	$foo->[0] = 1;
	@$foo = (1);
}});

call_is('my $foo = "bar";', 'print "foo";', "newSub ();\n");
sub_is('my $foo = "bar";', 'print "foo";',
q{sub newSub {
	my $foo = "bar";
}});

done_testing();

sub call_is {
	my ($code, $after_call, $expected_call) = @_;

	unless ($expected_call) {
		$expected_call = $after_call;
		$after_call = '';
	}

	is(_extractor($code, $after_call)->sub_call(), $expected_call);
}

sub sub_is {
	my ($code, $after_call, $expected_code) = @_;

	unless ($expected_code) {
		$expected_code = $after_call;
		$after_call = '';
	}

	eq_or_diff(_extractor($code, $after_call)->new_method(), $expected_code);
}

sub _extractor {
	my ($code, $after_call) = @_;

	return Devel::Refactor::ExtractMethod->new(
		sub_name => 'newSub',
		code_snippet => $code,
		after_call => $after_call,
		syntax_check => 1,
	);
}
