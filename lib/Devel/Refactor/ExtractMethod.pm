package Devel::Refactor::ExtractMethod;
use strict;
use warnings;
no warnings 'uninitialized';

use Devel::Refactor::Var;

sub perform {
    my $sub_name     = shift;
    my $code_snippet = shift;
    my $syntax_check = shift;

    my ($parms, $return_sub_call, $return_snippet) = _transform_snippet($sub_name, $code_snippet);

     if ($syntax_check) {
         $return_snippet = _syntax_check($parms, $return_sub_call, $return_snippet);
     }
     return ($return_sub_call, $return_snippet);
}


sub _transform_snippet {
    my ($sub_name, $code_snippet) = @_;

    my $reg;
    my $reg2;
	my @parms;
	my @inner_retvals;
	my @outer_retvals;
	my %vars = _parse_vars($code_snippet);
	my %local_vars = _parse_local_vars($code_snippet, \%vars);
	my %loop_vars = _parse_loop_vars($code_snippet, \%vars);

	my %var_type_replacement = (
		scalar => '$',
		hash => '%',
		array => '@',
	);

	foreach my $var ( map {values %$_} values %vars ) {
		my $parm = $var->converted_name();
		my $type = $var->type();

		if ( !defined( $local_vars{$type}->{$parm} ) ) {
			push @parms, $parm;

			if ($type ne 'scalar') {
				$reg2 = "\\$parm";
				(my $ref = $parm) =~ s/$var_type_replacement{$type}/\$/;
				$code_snippet =~ s/$reg2/$var_type_replacement{$type}$ref/g;

				$parm =~ s/$var_type_replacement{$type}/\$/;
				$reg = "\\$parm";

				$code_snippet =~ s/${reg}([[{])/$parm\-\>$1/g;
			}
		}
		elsif (!$loop_vars{$type}{$parm}) {
			if ($type eq 'scalar') {
				push @inner_retvals, $parm;
			}
			else {
				push @inner_retvals, "\\$parm";
			}
			push @outer_retvals, $parm;
		}
	}
    my $retval;
    my $return_call;
    my $tmp;

	if (scalar(@outer_retvals) > 0) {
		$return_call .= "my ";
		$return_call .= "(" if scalar(@outer_retvals) > 1;
		$return_call .= join ', ', map {my $tmp; ($tmp = $_) =~ s/[\@\%](.*)/\$$1/; $tmp} sort @outer_retvals;
		$return_call .= ")" if scalar(@outer_retvals) > 1;
		$return_call .= " = ";
	}
	$return_call .= "$sub_name (";
    $return_call .= join ', ',
         map { ( $tmp = $_ ) =~ s/(\%|\@)(.*)/\\$1$2/; $tmp } @parms;
    $return_call .= ");\n";
    
    $retval  = "sub $sub_name {\n";
	$retval .= "\tmy (" . join(',', map {
		($tmp = $_) =~ tr/%@/$/;$tmp
	} @parms) . ") = \@_;\n" if scalar(@parms > 0);

	if (scalar(@outer_retvals) > 0 && scalar(@parms) > 0) {
		$retval .= "\n";
	}

    $retval .= join("", map {"\t$_\n"} split /\n/, $code_snippet);
	if (scalar(@outer_retvals > 0)) {
		$retval .= "\treturn ";
		$retval .= "(" if scalar(@outer_retvals) > 1;
		$retval .= join ', ', sort @inner_retvals;
		$retval .= ")" if scalar(@outer_retvals) > 1;
		$retval .= ";\n";
	}
    $retval .= "}\n";

	return (\@parms, $return_call, $retval);
}

sub _parse_vars {
    my ($code_snippet) = @_;

	my %vars;

    # find the variables
    while ( $code_snippet =~ /([\$\@]\w+?)(\W{1,2})/g ) {
        my $var  = Devel::Refactor::Var->new(
			name => $1,
			hint => $2,
		);
		$vars{$var->type()}{$var->converted_name()} = $var;
    }

	return %vars;
}

sub _parse_local_vars {
    my ($code_snippet, $vars) = @_;

	my %local_vars;

    # figure out which are declared in the snippet
		foreach my $var ( map {values %$_} values %$vars ) {
			my $name = $var->converted_name();
			if ( $code_snippet =~ /\s*my\s*(\([^)]*?)?\Q$name\E([^)]*?\))?/ ) {
				$local_vars{$var->type()}{$name} = $var;
			}
		}

	return %local_vars;
}

sub _parse_loop_vars {
	my ($code_snippet, $vars) = @_;

	my %loop_vars;
	for my $var (map {values %$_} values %$vars) {
		if ($var->type() eq 'scalar') {
			my $name = $var->converted_name();
			if ( $code_snippet =~ /(?:for|foreach)\s+my\s*\Q$name\E\s*\(/ ) {
				$loop_vars{$var->type()}{$var->name()} = $var;
			}
		}
	}

	return %loop_vars;
}

sub _syntax_check{
    my ($parms, $sub_call, $new_code) = @_;
    my $tmp;

    my $eval_stmt;
	if (scalar(@$parms) > 0) {
		$eval_stmt = "my (". join(', ', @{$parms}) . ");\n";
	}
    $eval_stmt .= $sub_call;
    $eval_stmt .= $new_code;

	my $new_code_file = File::Temp->new();
	$new_code_file->print($eval_stmt);
	$new_code_file->flush();
	open(my $syntax_check, "-|", "perl -c $new_code_file 2>&1");
	my @file_with_errors = split /\n/, $new_code;
	while (my $err = <$syntax_check>) {
		chomp($err);
		if ($err =~ /line\s(\d+)/) {
			my $line = ($1 - 3);
			$err =~ s/at \S* line \d+, //;
			$file_with_errors[$line] .= " #<--- ".$err;
		}
	}
	close($syntax_check);
	return join("\n", @file_with_errors);
}

1;
