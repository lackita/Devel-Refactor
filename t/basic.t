#!/usr/bin/perl
# $Header: $
#
use strict;
use Test::More tests => 7;
use Data::Dumper;

use_ok 'Devel::Refactor';

my $rf = Devel::Refactor->new;
ok($rf && ref $rf && $rf->isa('Devel::Refactor'), "Get a new Devel::Refactor object.");

my @perlfiles = qw( foo.pl foo.pm foo.pod );
foreach my $fn (@perlfiles) {
    ok($rf->is_perlfile($fn), "'$fn' recognized as Perl file name.");
}
ok (! $rf->is_perlfile('foo.t'), "'foo.t' rejected as Perl file name.");

my $perlfiles = $rf->perl_file_extensions(['.t']);
ok($rf->is_perlfile('foo.t'), "'foo.t' recognized as Perl file name.");


