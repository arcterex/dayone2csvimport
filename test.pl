#!/usr/bin/perl -w
use strict;
use HTML::WikiConverter; 
use HTML::TokeParser::Simple;
use Text::Wrap;
use Data::Dumper;

my $base_url = 'http://arcterex.net';

my $wc = new HTML::WikiConverter( 
	dialect => 'Markdown',
	link_style  => 'inline',
	base_uri    => $base_url,
	strip_empty_tags => 1,
);  

my $s = <<'END';
<p>Very first <a href="http://arcterex.net/blog/archives/1997/07/73097.html">mention</a> is July 1997, before I got him when the litter of kittens was still too small to come home.</p>
<p><a href="http://arcterex.net/blog/assets_c/2013/05/IMG_0003-56.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/IMG_0003-56.html','popup','width=640,height=480,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/IMG_0003-thumb-500x375-56.jpg" width="500" height="375" alt="Corny and Andrea" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a><a href="http://arcterex.net/blog/assets_c/2013/05/IMG_4124-59.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/IMG_4124-59.html','popup','width=3264,height=2448,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/IMG_4124-thumb-500x375-59.jpg" width="500" height="375" alt="corny and rob" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a></p>
<p>And a couple from when he was a baby.</p>
<p><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html','popup','width=900,height=634,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-thumb-500x352-62.jpg" width="500" height="352" alt="king rd apartment - corny 10.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html','popup','width=900,height=603,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-thumb-500x335-65.jpg" width="500" height="335" alt="king rd apartment - corny 3.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a>He was my first "real" cat and was with me for almost as many years as he wasn't. I miss him but am happy for the time I had with him cuddling on the couch or sleeping on my shoulder at night and purring.</p>
END

$s =~ s/(^|\n)[\n\s]*/\n<\/p>$1<p>\n/g;
#print "INPUT\n----\n$s\n";

# clean html
print "\n-----\nCLEANING ... \n\n";
my $parser = HTML::TokeParser::Simple->new( string => $s);

my $cleaned = "";
while( my $token = $parser->get_token ) {
# clean up the image tag
	if( $token->is_tag('img')) {
		$token->delete_attr('width');
		$token->delete_attr('height');
		$token->delete_attr('class');
		$token->delete_attr('style');
	}

	# now clean up the a href tags *if* they are popups for images
	if( $token->is_tag('a') ) {
		print "Found A\n";
		print Dumper $token;
		if( $token->get_attr('onclick') ) { 
			print "Found onclick\n";
			print "Next 3:\n";
			print Dumper $parser->peek(3);
			print "END\n";
			next;
		}
	}


	$cleaned .= $token->as_is;
}

$s = $cleaned;

print "\n-----\nCLEANED\n------\n$cleaned\n------\n";
my $output_text = $wc->html2wiki($s); 
print "\n-----\nOUTPUT:\n";
print $output_text . "\n";

exit;
