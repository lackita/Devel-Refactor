package Devel::Refactor::ExtractMethod;
use strict;
use warnings;
no warnings 'uninitialized';

sub _parse_vars {
    my ($code_snippet) = @_;

    my $var;
    my $hint;
	my %vars;

    # find the variables
    while ( $code_snippet =~ /([\$\@]\w+?)(\W{1,2})/g ) {

        $var  = $1;
        $hint = $2;
        if ( $hint =~ /^{/ ) {    #}/ 
            $var =~ s/\$/\%/;
			$vars{hash}{$var}++;
        } elsif ( $hint =~ /^\[>/ ) {
            $var =~ s/\$/\@/;
			$vars{array}{$var}++;
        } elsif ( $var =~ /^\@/ ){
			$vars{array}{$var}++;
        } elsif ( $var =~ /^\%/ ) {
			$vars{hash}{$var}++;
        } else {
			$vars{scalar}{$var}++;
        }
    }

	return %vars;
}

sub _parse_local_vars {
    my ($code_snippet, $vars) = @_;

    my $reg;
    my $reg2;
    my $reg3;   # To find loops variables declared in for and foreach
	my %local_vars;
	my %loop_vars;

    # figure out which are declared in the snippet
    foreach my $var ( keys %{ $vars->{scalar} } ) {
        $reg  = "\\s*my\\s*\\$var\\s*[=;\(]";
        $reg2 = "\\s*my\\s*\\(.*?\\$var.*?\\)";
        $reg3 = "(?:for|foreach)\\s+my\\s*\\$var\\s*\\(";

        if ( $var =~ /(?:\$\d+$|\$[ab]$)/ ) {
			$local_vars{scalar}{$var}++;
        } elsif ( $code_snippet =~ /$reg|$reg2/ ) {
			$local_vars{scalar}{$var}++;
            # skip loop variables
            if ( $code_snippet =~ /$reg3/ ) {
				$loop_vars{scalar}{$var}++;
            }
        }
    }
    foreach my $var ( keys %{ $vars->{array}} ) {
        $var =~ s/\$/\@/;
        $reg  = "\\s*my\\s*\\$var\\s*[=;\(]";
        $reg2 = "\\s*my\\s*\\(.*?\\$var.*?\\)";

        if ( $code_snippet =~ /$reg|$reg2/ ) {
			$local_vars{array}{$var}++;
        }

    }
    foreach my $var ( keys %{ $vars->{hash}} ) {
        $var =~ s/\$/\%/;
        $reg  = "\\s*my\\s*\\$var\\s*[=;\(]";
        $reg2 = "\\s*my\\s*\\(.*?\\$var.*?\\)";

        if ( $code_snippet =~ /$reg|$reg2/ ) {
			$local_vars{hash}{$var}++;
        }
    }

	return {
		local => \%local_vars,
		loop => \%loop_vars,
	};
}

1;
