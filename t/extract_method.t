#!/usr/bin/perl

use strict;
use warnings;

use ExtractMethodTester;
use Test::More;

my $extractor = ExtractMethodTester->new(code => "print 'foo';");
$extractor->call_is("newSub ();\n");
$extractor->sub_is(q{sub newSub {
	print 'foo';
}});

$extractor->code("print \$foo;\nprint \$bar;");
$extractor->call_is("newSub (\$foo, \$bar);\n");
$extractor->sub_is(q{sub newSub {
	my ($foo, $bar) = @_;
	print $foo;
	print $bar;
}});

$extractor->args_hash(1);
$extractor->call_is("newSub (foo => \$foo, bar => \$bar);\n");
$extractor->sub_is(q{sub newSub {
	my (%args) = @_;
	print $args{foo};
	print $args{bar};
}});

$extractor->args_hash(0);
$extractor->code('my $foo = 1;');
$extractor->call_is("my \$foo = newSub ();\n");
$extractor->sub_is(q{sub newSub {
	my $foo = 1;
	return $foo;
}});

$extractor->code('(');
$extractor->call_is("newSub ();\n");
$extractor->sub_is(q{sub newSub {
	( #<--- syntax error near "(
}});

$extractor->code("\$foo{1} = 2;\n\%foo = (1 => 2);");
$extractor->call_is("newSub (\\\%foo);\n");
$extractor->sub_is(q{sub newSub {
	my ($foo) = @_;
	$foo->{1} = 2;
	%$foo = (1 => 2);
}});

$extractor->code("\$foo[0] = 1;\n\@foo = (1);");
$extractor->call_is("newSub (\\\@foo);\n");
$extractor->sub_is(q{sub newSub {
	my ($foo) = @_;
	$foo->[0] = 1;
	@$foo = (1);
}});

$extractor->code('my $foo = "bar";');
$extractor->after_call('print "foo";');
$extractor->call_is("newSub ();\n");
$extractor->sub_is(q{sub newSub {
	my $foo = "bar";
}});

done_testing();
