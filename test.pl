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
	image_tag_fallback => 0,
	escape_entities => 1,
	md_extra => 1,
	base_uri => "http://arcterex.net",
);  

my $s = <<'END';
I am trying to change this.  Hanging out tomorrow night, and through some of the work I'm doing with the High School Reunion stuff I've hooked up with an old one of "The Gang" (or at least got in contact) and will probably go out for a drink with Ben (met <a href="/blog/archives/2003/03/10/reunion_meeting_and_weekend_wrapup.html">at the mini-meeting</a>), so my social circle may expand a bit more.  I miss the old gang from <a href="http://merilus.com">work</a> though.  I miss my friends who have left on their own pursuits, be they right in <a href="http://userfriendly.org/community/iambe/daily.html">the</a> <a href="http://fozbaca.org">building</a> or <a href="http://staticred.net">right up the road</a> to hang with, or do something with.  Not that I don't have good friends still here, my point is that I miss my old friends.
a <a href="test.html">test url1</a>
a <a href="/test.html">test 2 url</a>
END

$s = <<'END';
This is <a href="/test1.html">link to just a page</a>.<BR/>
END


my $output_text = $wc->html2wiki($s); 
print "\n-----\nOUTPUT:\n";
print $output_text . "\n";
print "\n-----\nEND OUTPUT\n";

exit;
