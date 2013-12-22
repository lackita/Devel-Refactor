#!/usr/bin/perl

use strict;
use Test::More;
use Test::Differences;

use Devel::Refactor;
use Devel::Refactor::ExtractMethod;

call_is(
	code => "print 'foo';",
	expected_call => "newSub ();\n",
);
sub_is(
	code => "print 'foo';",
	expected_sub =>
q{sub newSub {
	print 'foo';
}},
);

call_is(
	code => 'print $foo;',
	expected_call => "newSub (\$foo);\n",
);
sub_is(
	code => 'print $foo;',
	expected_sub =>
q{sub newSub {
	my ($foo) = @_;
	print $foo;
}},
);

call_is(
	code => 'my $foo = 1;',
	expected_call => "my \$foo = newSub ();\n",
);
sub_is(
	code => 'my $foo = 1;', 
	expected_sub =>
q{sub newSub {
	my $foo = 1;
	return $foo;
}},
);

call_is(
	code => '(',
	expected_call => "newSub ();\n",,
);
sub_is(
	code => '(',
	expected_sub =>
q{sub newSub {
	( #<--- syntax error near "(
}},
);

call_is(
	code => "\$foo{1} = 2;\n\%foo = (1 => 2);",
	expected_call => "newSub (\\\%foo);\n",
);
sub_is(
	code => "\$foo{1} = 2;\n\%foo = (1 => 2);",
	expected_sub =>
q{sub newSub {
	my ($foo) = @_;
	$foo->{1} = 2;
	%$foo = (1 => 2);
}},
);

call_is(
	code => "\$foo[0] = 1;\n\@foo = (1);",
	expected_call => "newSub (\\\@foo);\n",
);
sub_is(
	code => "\$foo[0] = 1;\n\@foo = (1);",
	expected_sub =>
q{sub newSub {
	my ($foo) = @_;
	$foo->[0] = 1;
	@$foo = (1);
}},
);

call_is(
	code => 'my $foo = "bar";',
	after_call => 'print "foo";',
	expected_call => "newSub ();\n",
);
sub_is(
	code => 'my $foo = "bar";',
	after_call => 'print "foo";',
	expected_sub =>
q{sub newSub {
	my $foo = "bar";
}}
);

done_testing();

sub call_is {
	my (%args) = @_;

	is(_extractor($args{code}, $args{after_call})->sub_call(), $args{expected_call});
}

sub sub_is {
	my (%args) = @_;

	eq_or_diff(_extractor($args{code}, $args{after_call})->new_method(), $args{expected_sub});
}

sub _extractor {
	my ($code, $after_call) = @_;

	return Devel::Refactor::ExtractMethod->new(
		sub_name => 'newSub',
		code_snippet => $code,
		after_call => $after_call || '',
		syntax_check => 1,
	);
}
