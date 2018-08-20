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
	image_style => 'inline',
	base_uri    => $base_url,
	image_tag_fallback => 0,
	escape_entities => 1,
	md_extra => 1,
);  

my $s = <<'END';
<p>Very first <a href="http://arcterex.net/blog/archives/1997/07/73097.html">mention</a> is July 1997, before I got him when the litter of kittens was still too small to come home.</p>
<p><a href="http://arcterex.net/blog/assets_c/2013/05/IMG_0003-56.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/IMG_0003-56.html','popup','width=640,height=480,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/IMG_0003-thumb-500x375-56.jpg" width="500" height="375" alt="Corny and Andrea" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a><a href="http://arcterex.net/blog/assets_c/2013/05/IMG_4124-59.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/IMG_4124-59.html','popup','width=3264,height=2448,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/IMG_4124-thumb-500x375-59.jpg" width="500" height="375" alt="corny and rob" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a></p>
<p>And a couple from when he was a baby.</p>
<p><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html','popup','width=900,height=634,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-thumb-500x352-62.jpg" width="500" height="352" alt="king rd apartment - corny 10.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html','popup','width=900,height=603,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-thumb-500x335-65.jpg" width="500" height="335" alt="king rd apartment - corny 3.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a>He was my first "real" cat and was with me for almost as many years as he wasn't. I miss him but am happy for the time I had with him cuddling on the couch or sleeping on my shoulder at night and purring.</p>
END

my $s2 = <<'END';
The "out of box" experience is good, the shipping box is unique, fits the watch well, and there was no shifting of the watch.  There was no documentation inside, no quick start guide, but I suppose if you're the sort of person who guys a Smartwatch off of the internet via Kickstarter, you can figure stuff out yourself.  The watch is smaller than I thought it would be, but still not "tiny".  Definitely not a downside.  

<a href="http://arcterex.net/blog/assets_c/2013/02/IMG_2659-50.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/02/IMG_2659-50.html','popup','width=3264,height=2448,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/02/IMG_2659-thumb-500x375-50.jpg" width="500" height="375" alt="Pebble in Package" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a>

The screen is just the right size I think, or pretty close to it.  The wrist strap is less "plastic-y" than I thought.  Seeing the reviews didn't prepare me for the soft plastic that it is made out of. Not low quality as far as I can tell (not being a plastics expert), and pleasant against the wrist.

END

my $s3 = <<'END';
<p><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-62.html','popup','width=900,height=634,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%2010-thumb-500x352-62.jpg" width="500" height="352" alt="king rd apartment - corny 10.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a><a href="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html" onclick="window.open('http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-65.html','popup','width=900,height=603,scrollbars=no,resizable=no,toolbar=no,directories=no,location=no,menubar=no,status=no,left=0,top=0'); return false"><img src="http://arcterex.net/blog/assets_c/2013/05/king%20rd%20apartment%20-%20corny%203-thumb-500x335-65.jpg" width="500" height="335" alt="king rd apartment - corny 3.jpg" class="mt-image-center" style="text-align: center; display: block; margin: 0 auto 20px;" /></a>He was my first "real" cat and was with me for almost as many years as he wasn't. I miss him but am happy for the time I had with him cuddling on the couch or sleeping on my shoulder at night and purring.</p>

END
$s = <<'END';
Two entries in a row?  Madness.  That was what I thought about watching two movies in a row, first Karate Kid and then the new <a href="http://www.imdb.com/title/tt0429493/">A-Team</a> movie.
<p>
This one is going to be even quicker though, no high fallutin' prattling on with them big reviewers words.  Get your buddies, go out and have a pizza or burger and the local fast food joint, have a beer or two, then go see the movie.
<p>
That preview you've seen with the crazy stuff with the plane and the tank?  It's all like that.  Not the questionable CGI, but the pure unappolagetic <EM>fun</EM> of a crazy over the top movie that doesn't care about a thin plot or cardboard characters (even though the plot and characters are surprisingly good IMHO), but just wants you to sit down and hang on for a ride.  The actors are good matches for their 80's TV originals, the plot is a combination of origin story and first adventure, and the shit blowing up is just fun.  So go see it, you'll like it.  Unless you're the sort of person who wants to go see Sex in the City 2, in that case you're probably not going to like this movie at all.
<p>
Well worth it, see it in the theatre for the full effect, two thumbs up.
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


#print "\n-----\nCLEANED\n------\n$s\n------\n";
my $output_text = $wc->html2wiki($s); 
print "\n-----\nOUTPUT:\n";
print $output_text . "\n";
print "\n-----\nEND OUTPUT\n";

exit;
