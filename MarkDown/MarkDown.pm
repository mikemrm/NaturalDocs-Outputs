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

package NaturalDocs::Builder::MarkDown;

use base 'NaturalDocs::Builder::ParseNDMarkup';
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
    return 'MarkDown';
    };


sub relativeLink {
    my ($self, $source, $target) = @_;
    return '' if($source eq $target);
    my $inputDirectory = NaturalDocs::File->NoFileName($source);
    my $relativePath = NaturalDocs::File->MakeRelativePath($inputDirectory, $target);

    my ($relativeVolume, $relativeDirString, $relativeFile) = File::Spec->splitpath($relativePath);
    my $relativePathDirectory = File::Spec->catpath($relativeVolume, $relativeDirString, undef);

    if (!($relativeFile =~ tr/./_/))
        {  $relativeFile .= '_';  };

    $relativeFile =~ tr/ &?(){};#/_/;

    my $relativePathDir = File::Spec->catpath($relativeVolume, $relativeDirString, $relativeFile);

    return $relativePathDir;

}

sub StringToHashString {
    my ($self, $string) = @_;
    $string =~ s/[^a-zA-Z0-9_]+/-/g;
    return lc($string);
}

sub BuildFile #(sourceFile, parsedFile)
    {
        my ($self, $sourceFile, $parsedFile) = @_;
        my $outputFile = $self->OutputFileOf($sourceFile);

        # 99.99% of the time the output directory will already exist, so this will actually be more efficient.  It only won't exist
        # if a new file was added in a new subdirectory and this is the first time that file was ever parsed.
        if (!open(OUTPUTFILEHANDLE, '>' . $outputFile))
            {
            NaturalDocs::File->CreatePath( NaturalDocs::File->NoFileName($outputFile) );

            open(OUTPUTFILEHANDLE, '>' . $outputFile)
                or die "Couldn't create output file " . $outputFile . "\n";
            };

        my $output = '';
        foreach my $part (@$parsedFile){

            my $custom_elements = {
                'link' => sub {
                    my ($self, $elem, $alts) = @_;
                    use Data::Dumper;
                    if($elem->{reference}){
                        my $link = $self->relativeLink($sourceFile, $elem->{reference}->File());
                        $link .= '#' . $self->StringToHashString('[ ' . $elem->{reference}->Type() . ' ] ' . $elem->{target});
                        if($elem->{reference}->Summary()){
                            my $summary = $self->JoinElements($self->ParseNDMarkupString($elem->{reference}->Summary(), $part, $sourceFile));
                            my $cleanSummary = NaturalDocs::NDMarkup->ConvertAmpChars($summary);
                            $link .= ' "' . $cleanSummary . '"';
                        }
                        return '[' . $elem->{content} . '](' . $link . ')';
                    } else {
                        return NaturalDocs::NDMarkup->ConvertAmpChars($elem->{original});
                    }
                }
            };

            my $list_link = {
                'link' => sub {
                    my ($self, $elem, $alts) = @_;
                    use Data::Dumper;
                    if($elem->{reference}){
                        my $link = $self->relativeLink($sourceFile, $elem->{reference}->File());
                        my $title = '';
                        $link .= '#' . $self->StringToHashString('[ ' . $elem->{reference}->Type() . ' ] ' . $elem->{target});
                        if($elem->{reference}->Summary()){
                            my $summary = $self->JoinElements($self->ParseNDMarkupString($elem->{reference}->Summary(), $part, $sourceFile));
                            $title = NaturalDocs::NDMarkup->ConvertAmpChars($summary);
                        }
                        return '<a href="' . $link . '" title="' . $title . '">' . NaturalDocs::NDMarkup->ConvertAmpChars($elem->{content}) . '</a>';
                    } else {
                        return NaturalDocs::NDMarkup->ConvertAmpChars($elem->{original});
                    }
                }
            };


            $output .= '# [ ' . $part->Type() . " ] " . $part->Title() . "\n\n";
            if(defined($part->Body())){
                my $data = $self->ParseNDMarkup($part, $sourceFile);
                foreach my $content (@$data){
                    if($content->{element_type} eq 'text'){
                        $output .= $content->{content} . "\n\n";
                    } elsif($content->{element_type} eq 'section') {
                        $output .= '## ' . $self->JoinElements($content->{content}, $custom_elements) . "\n\n";
                    } elsif($content->{element_type} eq 'link') {
                        my $link = $self->JoinElements($content->{content}, $custom_elements);
                        print(Dumper($link));
                        $output .= '## ' . $self->JoinElements($content->{content}, $custom_elements) . "\n\n";
                    } elsif($content->{element_type} eq 'block_text') {
                        $output .= $self->JoinElements($content->{content}, $custom_elements) . "\n\n";
                    } elsif($content->{element_type} eq 'entry_description') {
                        my $left_padd = 0;
                        my $right_padd = 0;
                        my @entries;
                        foreach my $entry (@{ $content->{entries} }){
                            my $left_raw = $self->JoinElements($entry->{entry}, $list_link);
                            my $left = $self->JoinElements($entry->{entry});
                            my $right_raw = $self->JoinElements($entry->{description}, $list_link);
                            my $right = $self->JoinElements($entry->{description});
                            $left_padd = length($left) if(length($left) > $left_padd);
                            $right_padd = length($right) if(length($right) > $right_padd);
                            push @entries, [$left_raw, $left, $right_raw, $right];
                        }
                        $output .= '<pre>' . "\n";
                        foreach my $entry (@entries){
                            $output .= "<em>" . $entry->[0] . '</em>' . (' ' x ($left_padd - length($entry->[1]))) . ' | ' . $entry->[2] . (' ' x ($right_padd - length($entry->[3]))) . "\n";
                        }
                        $output .= '</pre>' . "\n\n";
                    }
                }
                $output .= "---\n\n"
            }
        }
        #print $output;
        print OUTPUTFILEHANDLE $output;
        close(OUTPUTFILEHANDLE);
    };


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

    $outputDirectory = NaturalDocs::File->JoinPaths( $outputDirectory, 'MarkDown' . ($inputDirectoryName != 1 ? $inputDirectoryName : ''), 1 );

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
