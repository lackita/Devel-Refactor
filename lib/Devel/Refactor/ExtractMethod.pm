package Devel::Refactor::ExtractMethod;
use strict;
use warnings;
no warnings 'uninitialized';

use Moose;
use Devel::Refactor::Variable;
use File::Temp;

has 'sub_name' => (is => 'ro');
has 'code_snippet' => (is => 'ro');
has 'after_call' => (
	is => 'ro',
	default => sub {''},
);
has 'args_hash' => (
	is => 'ro',
	isa => 'Bool',
);

sub sub_call {
	my ($self) = @_;

	my $return_call;
	my @return_vars = $self->_return_vars($self->code_snippet());
	if (scalar(@return_vars) > 0) {
		$return_call .= "my ";
		$return_call .= "(" if scalar(@return_vars) > 1;
		$return_call .= join ', ', sort map {$_->scalar_name()} @return_vars;
		$return_call .= ")" if scalar(@return_vars) > 1;
		$return_call .= " = ";
	}

	my @parameters = $self->_parameters_for($self->code_snippet());
	$return_call .= $self->sub_name() . " (";
	if ($self->args_hash()) {
		$return_call .= join(', ', map {$_->name() . " => " . $_->scalar_name()} @parameters);
	}
	else {
		$return_call .= join ', ', map {$_->escaped_name()} @parameters;
	}
    $return_call .= ");\n";
	return $return_call;
}

sub new_method {
	my ($self) = @_;

	my @return_vars = $self->_return_vars($self->code_snippet());
	my @parameters = $self->_parameters_for($self->code_snippet());

    my $retval = "sub " . $self->sub_name() . " {\n";
	if ($self->args_hash()) {
		$retval .= "\tmy (\%args) = \@_;\n";
	}
	else {
		$retval .= "\tmy (" . join(', ', map {
			$_->scalar_name()
		} @parameters) . ") = \@_;\n" if scalar(@parameters) > 0;
	}

	if (scalar(@return_vars) > 0 && scalar(@parameters) > 0) {
		$retval .= "\n";
	}

    $retval .= join("", map {"\t$_\n"} split /\n/, $self->code_snippet());
	foreach my $var ( @parameters ) {
		if ( !$var->is_local_to($self->code_snippet()) ) {
			my $parm = $var->converted_name();
			if ($var->type() ne 'scalar') {
				my $prefix = $var->prefix();
				my $ref = $var->scalar_name();
				$retval =~ s/\Q$parm\E/$prefix$ref/g;
				$retval =~ s/\Q$ref\E([[{])/$ref\-\>$1/g;
			}
			elsif ($self->args_hash()) {
				my $name = $var->name();
				$retval =~ s/\Q$parm\E/\$args{$name}/g;
			}
		}
	}

	if (scalar(@return_vars > 0)) {
		$retval .= "\treturn ";
		$retval .= "(" if scalar(@return_vars) > 1;
		$retval .= join ', ', sort map {$_->escaped_name()} @return_vars;
		$retval .= ")" if scalar(@return_vars) > 1;
		$retval .= ";\n";
	}
    $retval .= "}\n";

	return $self->_mark_syntax_errors($retval);
}

sub _return_vars {
	my ($self) = @_;
	return grep {
		$_->is_local_to($self->code_snippet())
		&& !$_->is_iterator_in($self->code_snippet())
		&& (!$self->after_call() || $_->referenced_in($self->after_call()))
	} $self->_vars_for($self->code_snippet());
}

sub _parameters_for {
	my ($self) = @_;
	return grep {
		!$_->is_local_to($self->code_snippet())
	} $self->_vars_for($self->code_snippet());
}

sub _vars_for {
    my ($self) = @_;

	my %vars;

    # find the variables
	my $code_snippet = $self->code_snippet();# have to use a temporary variable to appease looping over /.../g
    while ( $code_snippet =~ /([\$\@]\w+?)(\W{1,2})/g ) {
        my $var  = Devel::Refactor::Variable->new(
			variable_name => $1,
			hint => $2,
		);
		$vars{$var->converted_name()} = $var;
    }

	return values %vars;
}

sub _mark_syntax_errors{
    my ($self, $new_code) = @_;

    my $eval_stmt;
    $eval_stmt .= $new_code;

	my $new_code_file = File::Temp->new();
	$new_code_file->print($eval_stmt);
	$new_code_file->flush();
	open(my $syntax_check, "-|", "perl -c $new_code_file 2>&1");
	my @file_with_errors = split /\n/, $new_code;
	while (my $err = <$syntax_check>) {
		chomp($err);
		if ($err =~ /line\s(\d+)/) {
			my $line = ($1 - 2);
			$err =~ s/at \S* line \d+, //;
			$file_with_errors[$line] .= " #<--- ".$err;
		}
	}
	close($syntax_check);
	return join("\n", @file_with_errors);
}

1;
