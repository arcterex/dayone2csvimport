#!/usr/bin/perl -w
use strict;
use HTML::WikiConverter; 
use HTML::TokeParser::Simple;
use Text::Wrap;
use Data::Dumper;

my $base_url = 'http://arcterex.net';
my $debug = 1;

my $wc = new HTML::WikiConverter( 
	dialect => 'Markdown',
	link_style  => 'inline',
	image_style => 'inline',
	base_uri    => $base_url,
	p_strict 	=> 1,
	image_tag_fallback => 0,
	escape_entities => 1,
	md_extra => 1,
);  

my $s = <<'END';
foo
<ul>
<li>saving your political skin in the eyes of the rest of the world as you attack a basically contained nation?</EM>
<li>saving your political skin in the eyes of the rest of the world as you attack a basically contained nation?</EM>
</ul>
<EM>*sigh*</EM> Of c
<ul>
<li>saving your political skin in the eyes of the rest of the world as you attack a basically contained nation?</EM>
<li>saving your political skin in the eyes of the rest of the world as you attack a basically contained nation?</EM>
</ul>
<p>
<EM>*sigh*</EM> Of c
</P>
END

#$s =~ s/(^|\n)[\n\s]*/\n<\/p>$1<p>\n/g;
print "INPUT\n----\n$s\n";

# clean html
#print "\n-----\nCLEANING ... \n\n";
#my $parser = HTML::TokeParser::Simple->new( string => $s);
#my $cleaned;
#
#while( my $token = $parser->get_token ) {
## clean up the image tag
#	if( $token->is_tag('img')) {
#		$token->delete_attr('width');
#		$token->delete_attr('height');
#		$token->delete_attr('class');
#		$token->delete_attr('style');
#	}
#
#	$cleaned .= $token->as_is;
#}

# Now modify the cleaned text and use a regex to replace:
# <a href onclick=.*><img.*></a>
# with
# <img.*>
#$cleaned =~ s/<a href=.*?>(<img.*?>)<\/a>/$1/g;

#$s = $cleaned;

sub fix_html_li
{
    my $input = shift @_; 

    # if it has a <ul> without newlines, add them
    print "DEBUG: Checking for un-ended list\n" if $debug;
    if( $input =~ /<\/ul>\s+(?!<p)/gmi ) {
        print "DEBUG: Found un-ended list\n" if $debug;
        $input =~ s/<\/ul>\s+(?!<p)/<ul>\n<p>\n/gmi;
    }   

    return $input;
}

print "INPUT: \n------\n$s\n----\n";
#$s = fix_html_li($s);
print "FIXED \n------\n$s\n----\n";

my $output_text = $wc->html2wiki($s); 
print "\n-----\nOUTPUT:\n";
print $output_text . "\n";
print "\n-----\nEND OUTPUT\n";

exit;
