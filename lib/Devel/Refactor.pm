# Refactor.pm - refactor Perl code.
# $Header: $
#
###############################################################################
=head1 NAME

Devel::Refactor - Perl extension for refactoring Perl code.

=head1 VERSION

$Revision: $  This is the CVS revision number.

=head1 File Interface

These will produce a file in your current directory called refactor.patch when
the provided script refactor.pl is called.

After performing each of these refactorings, the modified file is run through
perltidy.  Make sure you have a .perltidyrc file set up, or else applying the
patch file from a refactoring will probably reformat your code in an undesirable
way.

=head2 extract method

Extract the code in Foo.pm to a method called bar, starting at character 200,
and 20 characters long:

	refactor.pl Foo.pm extract_method bar 200 20

=head1 Programmatic Interface

=head2 SYNOPSIS

  use Devel::Refactor;
  
  my $refactory = Devel::Refactor->new;
  
  my ($new_sub_call,$new_sub_code) =
     $refactory->extract_subroutine($sub_name, $code_snippet);

  my $files_to_change = $refactory->rename_subroutine('./path/to/dir',
                                                      'oldSubName','newSubName');
  # $files_to_change is a hashref where keys are file names, and values are
  # arrays of hashes with line_number => new_text
  
=head2 ABSTRACT

Perl module that facilitates refactoring Perl code.  

=head2 DESCRIPTION

The B<Devel::Refactor> module is for code refactoring. 

While B<Devel::Refactor> may be used from Perl programs, it is also designed to be
used with the B<EPIC> plug-in for the B<eclipse> integrated development environment.

=cut

package Devel::Refactor;

use strict;
use warnings;

use Cwd;
use Devel::Refactor::ExtractMethod;
use Devel::Refactor::RenameMethod;
use File::Basename;
use File::Temp;

our $VERSION = '0.06';

our $DEBUG = 0;

our %perl_file_extensions = (
    '\.pl$' => 1,
    '\.pm$' => 1,
    '\.pod$' => 1,
);

=head2 CLASS METHODS

Just the constructor for now.

=head3 new

Returns a new B<Devel::Refactor> object.

=cut
# TODO: List the object properties that are initialized.

sub new {
    my $class        = shift;
    $DEBUG           = shift;

    my $self = {
        perl_file_extensions       => { %perl_file_extensions },
    };

    bless $self, $class;
    
    return $self;
}



=head2 PUBLIC OBJECT METHODS

Call on a object returned by new().

=head3 extract_subroutine($new_name,$old_code [,$syntax_check])

Pass it a snippet of Perl code that belongs in its own subroutine as
well as a name for that sub.  It figures out which variables
need to be passed into the sub, and which variables might be
passed back.  It then produces the sub along with a call to
the sub.

Hashes and arrays within the code snippet are converted to 
hashrefs and arrayrefs.

If the I<syntax_check> argument is true then a sytax check is performed
on the refactored code.

Example:

    $new_name = 'newSub';
    $old_code = <<'eos';
      my @results;
      my %hash;
      my $date = localtime;
      $hash{foo} = 'value 1';
      $hash{bar} = 'value 2';
      for my $loopvar (@array) {
         print "Checking $loopvar\n";
         push @results, $hash{$loopvar} || '';
      }
    eos

    ($new_sub_call,$new_code) = $refactory->extract_subroutine($new_name,$old_code);
    # $new_sub_call is 'my ($date, $hash, $results) = newSub (\@array);'
    # $new_code is
    # sub newSub {
    #     my $array = shift;
    # 
    #   my @results;
    #   my %hash;
    #   my $date = localtime;
    #   $hash{foo} = 'value 1';
    #   $hash{bar} = 'value 2';
    #   for my $loopvar (@$array) {
    #      print "Checking $loopvar\n";
    #      push @results, $hash{$loopvar} || '';
    #   }
    # 
    # 
    #     return ($date, \%hash, \@results);
    # }


Included in the examples directory is a script for use in KDE
under Linux.  The script gets its code snippet from the KDE 
clipboard and returns the transformed code the same way.  The
new sub name is prompted for via STDIN.

=cut

sub extract_subroutine {
    my ($self, $sub_name, $code_snippet, $syntax_check) = @_;
	my $extract_method = Devel::Refactor::ExtractMethod->new(
		sub_name => $sub_name,
		code_snippet => $code_snippet,
		syntax_check => $syntax_check,
	);
	return ($extract_method->sub_call(), $extract_method->new_method());
}

=head3 rename_subroutine($where,$old_name,$new_name,[$max_depth])

I<where> is one of:
  path-to-file
  path-to-directory
 
If I<where> is a directory then all Perl files (default is C<.pl>, C<.pm>,
and C<.pod> See the B<perl_file_extensions> method.) in that directory and its'
descendents (to I<max_depth> deep,) are searched.

Default for I<max_depth> is 0 -- just the directory itself;
I<max_depth> of 1 means the specified directory, and it's
immediate sub-directories; I<max_depth> of 2 means the specified directory,
it's sub-directories, and their sub-directrories, and so forth.
If you want to scan very deep, use a high number like 99.

If no matches are found then returns I<undef>, otherwise:

Returns a hashref that tells you which files you might want to change,
and for each file gives you the line numbers and proposed new text for that line.
The hashref looks like this,  where I<old_name>
was found on two lines in the first file and on one line in the second file:

 {
   ./path/to/file1.pl => [
                           { 11  => "if (myClass->newName($x)) {\n" },
                           { 27  => "my $result = myClass->newName($foo);\n"},
                         ],
   ./path/to/file2.pm => [
                           { 235 => "sub newName {\n"},
                         ],
 }

The keys are paths to individual files. The values are arraryrefs
containing hashrefs where the keys are the line numbers where I<old_name>
was found and the values are the proposed
new line, with I<old_name> changed to I<new_name>.

=cut

sub rename_subroutine {
    my ($self, $where, $old_name, $new_name, $max_depth) = @_;

	my $rename_method = Devel::Refactor::RenameMethod->new(
		perl_file_extensions => $self->perl_file_extensions(),
	);

	return $rename_method->perform($where, $old_name, $new_name, $max_depth);
}

=head3 is_perlfile($filename)

Takes a filename or path and returns true if the file has one of the
extensions in B<perl_file_extensions>, otherwise returns false.

=cut
sub is_perlfile {
    my ($self,$filename) = @_;
    my ($name,$path,$suffix) = fileparse($filename,keys %{$self->perl_file_extensions});
    return $suffix;
}

=head2 OBJECT ACCESSORS

These object methods return various data structures that may be stored
in a B<Devel::Refactor> object. In some cases the method also allows
setting the property, e.g. B<perl_file_extensions>.

=cut

=head3 get_new_code

Returns the I<return_snippet> object property.

=cut
sub get_new_code{
    my $self = shift;
    
    return $self->{return_snippet};
}

=head3 get_eval_results

Returns the I<eval_err> object property.

=cut
sub get_eval_results{
    my $self = shift;
    
    return $self->{eval_err};
}


=head3 get_sub_call

Returns the I<return_sub_call> object property.

=cut
sub get_sub_call{
    my $self = shift;
    
    return $self->{return_sub_call};
}


=head3 get_scalars

Returns an array of the keys from I<scalar_vars> object property.
=cut

sub get_scalars {
    my $self = shift;

    return sort keys %{ $self->{scalar_vars} };
}

=head3 get_arrays

Returns an array of the keys from the I<array_vars> object property.
=cut

sub get_arrays {
    my $self = shift;

    return sort keys %{ $self->{array_vars} };
}

=head3 get_hashes

Returns an array of the keys from the I<hash_vars> object property.

=cut

sub get_hashes {
    my $self = shift;

    return sort keys %{ $self->{hash_vars} };
}

=head3 get_local_scalars

Returns an array of the keys from the I<local_scalars> object property.

=cut
sub get_local_scalars {
    my $self = shift;

    return sort keys %{ $self->{local_scalars} };
}

=head3 get_local_arrays

Returns an array of the keys from the I<local_arrays> object property.

=cut
sub get_local_arrays {
    my $self = shift;

    return sort keys %{ $self->{local_arrays} };
}

=head3 get_local_hashes

Returns an array of the keys from the I<local_hashes> object property.

=cut

sub get_local_hashes {
    my $self = shift;

    return sort keys %{ $self->{local_hashes} };
}

=head3 perl_file_extensions([$arrayref|$hashref])

Returns a hashref where the keys are regular expressions that match filename
extensions that we think are for Perl files. Default are C<.pl>,
C<.pm>, and C<.pod>

If passed a hashref then it replaces the current values for this object. The
keys should be regular expressions, e.g. C<\.cgi$>.

If passed an arrayref then the list of values are added as valid Perl
filename extensions. The list should be filename extensions, NOT regular expressions,
For example:

  my @additonal_filetypes = qw( .ipl .cgi );
  my $new_hash = $refactory->perl_file_extensions(\@additional_filetypes);
  # $new_hash = {
  #   '\.pl$'   => 1,
  #   '\.pm$'   => 1,
  #   '\.pod$'  => 1,
  #   '\.ipl$'  => 1,
  #   '\.cgi$'  => 1,
  #   '\.t$'    => 1,
  # }

=cut

sub perl_file_extensions {
    my($self,$args) = @_;
    if (ref $args eq 'HASH') {
        $self->{perl_file_extensions} = $args;
    } elsif (ref $args eq 'ARRAY') {
        map $self->{perl_file_extensions}->{"\\$_\$"} = 1 , @$args;
    }
    return $self->{perl_file_extensions};
}


=head2 TODO LIST

=over 2

=item Come up with a more uniform approach to B<ACCESSORS>.

=item Add more refactoring features, such as I<add_parameter>.

=item Add a SEE ALSO section with URLs for eclipse/EPIC, refactoring.com, etc.

=back

=cut

1; # File must return true when compiled. Keep Perl happy, snuggly and warm.

__END__

=head1 AUTHOR

Scott Sotka, E<lt>ssotka@barracudanetworks.comE<gt>
Colin Williams, E<lt>lackita@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Scott Sotka
Copyright 2014 by Colin Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
