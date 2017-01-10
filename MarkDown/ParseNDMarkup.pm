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
use HTML::DOM;

package NaturalDocs::Builder::ParseNDMarkup;

use base 'NaturalDocs::Builder::Base';

sub GetElement {
    my ($self, $elem, $parsedSection, $sourceFile) = @_;

    my @data;
    
    foreach my $child ($elem->content_list()){
        if($child->tag() eq '~text'){
            push @data, {
                'element_type' => 'text',
                'content' => $child->attr('text')
            };
        } elsif($child->tag() eq 'h1'){
            push @data, {
                'element_type' => 'section',
                'content' => $self->GetElement($child, $parsedSection, $sourceFile)
            };
        } elsif($child->tag() eq 'p'){
            push @data, {
                'element_type' => 'block_text',
                'content' => $self->GetElement($child, $parsedSection, $sourceFile)
            };
        } elsif($child->tag() eq 'code'){
            push @data, {
                'element_type' => 'code',
                'type' => $child->attr('type'),
                'content' => $child->as_text()
            };
        } elsif($child->tag() eq 'a'){
            my $link_data = {
                'element_type' => 'link',
                'link_type' => $child->attr('data-type'),
                'target' => $child->attr('href'),
                'content' => $child->attr('name'),
                'reference' => undef
            };

            #my $plainTarget = $self->RestoreAmpChars($target);

            my $symbol = NaturalDocs::SymbolString->FromText($child->attr('href'));
            $link_data->{reference} = NaturalDocs::SymbolTable->References(::REFERENCE_TEXT(), $symbol, $parsedSection->Package(),
                                                                                                    $parsedSection->Using(), $sourceFile);
            

            $link_data->{'original'} = $child->attr('data-original') if($child->attr('data-type') eq 'link');
            push @data, $link_data;
        } elsif($child->tag() eq 'dl'){
            my $elem_data = {
                'element_type' => 'entry_description',
                'entries' => []
            };
            my $entries = $self->GetElement($child, $parsedSection, $sourceFile);

            if(scalar(@$entries) % 2 == 0){
                for(my $j = 0; $j < scalar(@$entries); $j += 2){
                    my $entry = $entries->[$j];
                    my $desc = $entries->[$j + 1];

                    if($entry->{element_type} eq 'text') {
                        $entry = [$entry];
                    } else {
                        $entry = $entry->{content};
                    }

                    if($desc->{element_type} eq 'text') {
                        $desc = [$desc];
                    } else {
                        $desc = $desc->{content};
                    }


                    push @{ $elem_data->{entries} }, {'entry' => $entry, 'description' => $desc};
                }
            }

            push @data, $elem_data;
        } else {
            my $elem_data = {
                'element_type' => $child->tag()
            };
            my @attribs = $child->all_attr_names();
            foreach my $attrib (@attribs){
                $attrib =~ s/^data-//g;
                $elem_data->{$attrib} = $child->attr($attrib) unless(substr($attrib, 0, 1) eq '_');
            }
            $elem_data->{content} = $self->GetElement($child, $parsedSection, $sourceFile);
            push @data, $elem_data;
        }
    }
    return \@data;
}

sub JoinElements {
    my ($self, $elements, $alts) = @_;
    $alts = {} if(!defined($alts));
    use Data::Dumper;
    my $output = '';
    foreach my $elem (@$elements){
        if(defined($alts->{$elem->{element_type}})) {
            $output .= $alts->{$elem->{element_type}}->($self, $elem, $alts);
        } elsif(ref(\$elem->{content}) eq 'SCALAR'){
            $output .= $elem->{content};
        } else {
            $output .= $self->JoinElements($elem->{content}, $alts);
        }
    }
    return $output;
}

sub ParseNDMarkup {
    my ($self, $parsedSection, $sourceFile) = @_;
    return [] unless(defined($parsedSection));
    my $NDMarkup = $parsedSection->Body();
    chomp($NDMarkup);
    $NDMarkup =~ s/<(link|url|email) target="([^"]+)" name="([^"]+)"( original="([^"]+)")?>/<a href="$2" name="$3" data-original="$5" data-type="$1">$3<\/a>/g;
    $NDMarkup =~ s/<(\/)?h>/<$1h1>/g;
    my $x = new HTML::DOM;
    $x->write('<html><body>' . $NDMarkup . '<body></html>');
    $x->close();
    my $html = $x->getElementsByTagName('body');
    my $body = $html->[0];
    return $self->GetElement($body, $parsedSection, $sourceFile);
}

sub ParseNDMarkupString {
    my ($self, $string, $parsedSection , $sourceFile) = @_;
    $parsedSection->SetBody($string);
    return $self->ParseNDMarkup($parsedSection, $sourceFile);
}

#
#   Function: BuildTextLink
#
#   Creates a HTML link to a symbol, if it exists.
#
#   Parameters:
#
#       target  - The link text.
#       name - The link name.
#       original - The original text as it appears in the source.
#       package  - The package <SymbolString> the link appears in, or undef if none.
#       using - An arrayref of additional scope <SymbolStrings> the link has access to, or undef if none.
#       sourceFile  - The <FileName> the link appears in.
#
#       Target, name, and original are assumed to still have <NDMarkup> amp chars.
#
#   Returns:
#
#       The link in HTML, including tags.  If the link doesn't resolve to anything, returns the HTML that should be substituted for it.
#
sub BuildTextLink #(target, name, original, package, using, sourceFile)
    {
    my ($self, $target, $name, $original, $package, $using, $sourceFile) = @_;

    #my $plainTarget = $self->RestoreAmpChars($target);

    my $symbol = NaturalDocs::SymbolString->FromText($target);
    my $symbolTarget = NaturalDocs::SymbolTable->References(::REFERENCE_TEXT(), $symbol, $package, $using, $sourceFile);
    return $symbolTarget->File();
}
1;