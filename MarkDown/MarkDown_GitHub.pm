###############################################################################
#
#   Class: NaturalDocs::Builder::Base
#
###############################################################################
#
#   A base class for all Builder output formats.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2010 Greg Valure
# Natural Docs is licensed under version 3 of the GNU Affero General Public License (AGPL)
# Refer to License.txt for the complete details

use strict;
use integer;
use Data::Dumper;

package NaturalDocs::Builder::MarkDown_GitHub;

use base 'NaturalDocs::Builder::MarkDown';
use File::Spec;

#
#   Function: INIT
#
#   Define this function to call <NaturalDocs::Builder->Add()> so that <NaturalDocs::Builder> knows about this package.
#   Packages are defined this way so that new ones can be added without messing around in other code.
#

sub INIT
    {
    NaturalDocs::Builder->Add(__PACKAGE__);
    };

#
#   Function: CommandLineOption
#
#   Define this function to return the text that should be put in the command line after -o to use this package.  It cannot have
#   spaces and is not case sensitive.
#
#   For example, <NaturalDocs::Builder::HTML> returns 'html' so someone could use -o html [directory] to use that package.
#
sub CommandLineOption
    {
    return 'MarkDown_GitHub';
    };

sub relativeLink {
    my ($self, $source, $target) = @_;
    return '' if($source eq $target);

    my ($relativeVolume, $relativeDirString, $relativeFile) = File::Spec->splitpath($target);

    if (!($relativeFile =~ tr/./_/))
        {  $relativeFile .= '_';  };

    $relativeFile =~ tr/ &?(){};#/_/;

    return $relativeFile;

}


#
#   Function: OutputFileOf
#
#   Returns the output file name of the source file.  Will be undef if it is not a file from a valid input directory.
#
sub OutputFileOf #(sourceFile)
    {
    my ($self, $sourceFile) = @_;

    my ($inputDirectory, $relativeSourceFile) = NaturalDocs::Settings->SplitFromInputDirectory($sourceFile);
    if (!defined $inputDirectory)
        {  return undef;  };

    my $outputDirectory = NaturalDocs::Settings->OutputDirectoryOf($self);
    my $inputDirectoryName = NaturalDocs::Settings->InputDirectoryNameOf($inputDirectory);

    $outputDirectory = NaturalDocs::File->JoinPaths( $outputDirectory, 'MarkDown_GitHub' . ($inputDirectoryName != 1 ? $inputDirectoryName : ''), 1 );

    # We need to change any extensions to dashes because Apache will think file.pl.html is a script.
    # We also need to add a dash if the file doesn't have an extension so there'd be no conflicts with index.html,
    # FunctionIndex.html, etc.

    if (!($relativeSourceFile =~ tr/./_/))
        {  $relativeSourceFile .= '_';  };

    $relativeSourceFile =~ tr/ &?(){};#/_/;
    $relativeSourceFile .= '.md';

    return NaturalDocs::File->JoinPaths($outputDirectory, $relativeSourceFile);
    };

1;