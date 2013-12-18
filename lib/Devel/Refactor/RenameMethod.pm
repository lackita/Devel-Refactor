package Devel::Refactor::RenameMethod;
use strict;
use warnings;
no warnings 'uninitialized';

use File::Basename;
use Moose;

has perl_file_extensions => (is => 'ro');

# Scan a directory, possibly recuring into sub-directories.
sub _scan_directory_for_string {
    my ($self, $old_name,$new_name,$where,$hash,$depth) = @_;
    my $dh;
    opendir $dh, $where ||
       die "Could not open directory '$where': $!";
    my @files = grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    close $dh;
    $depth--;
    foreach my $file (@files) {
        $file = "$where/$file";  # add the directory back on to the path
        if (-f $file && $self->is_perlfile($file)) {
            $hash->{$file} = $self->_scan_file_for_string($old_name,$new_name,$file);
        }
        if (-d $file && $depth >= 0) {
            # It's a directory, so call this method on the directory.
            $self->_scan_directory_for_string($old_name,$new_name,$file,$hash,$depth);
        }
    }
    return $hash;
}

# returns arrayref of hashrefs, or undef
sub _scan_file_for_string {
	my ($self, $old_name, $new_name, $file) = @_;

    my $fh;
    
    open $fh, "$file"
          || die("Could not open code file '$file' - $!");

    my $line_number = 0;
    my @lines;
    my $regex1 = '(\W)(' . $old_name . ')(\W)'; # Surrounded by non-word characters
    my $regex2 = "^$old_name(" . '\W)';  # At start of line
    while (<$fh>) {
        $line_number++;
        # Look for $old_name surrounded by non-word characters, or at start of line
        if (/$regex1/o or /$regex2/o) {
            my $new_line = $_;
            $new_line =~ s/$regex1/$1$new_name$3/g;
            $new_line =~ s/$regex2/$new_name$1/;
            my $hash = {$line_number => $new_line};
            push @lines, $hash;
        }
    }
    close $fh;
    return @lines ? \@lines : undef;
}

=head2 is_perlfile($filename)

Takes a filename or path and returns true if the file has one of the
extensions in B<perl_file_extensions>, otherwise returns false.

=cut
sub is_perlfile {
    my ($self,$filename) = @_;
    my ($name,$path,$suffix) = fileparse($filename,keys %{$self->perl_file_extensions});
    return $suffix;
}

1;
