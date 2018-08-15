#!/usr/bin/perl -w
use strict;
use HTML::WikiConverter; 
my $s = '
<p>This is a line</p>
<p>This is another line!</p>
[!-- this is a comment --]
<ul>
	<li>list1</li>
	<li>list2</li>
</ul>'; 
my $wc = new HTML::WikiConverter( 
	dialect => 'Markdown' 
);  
my $output_text = $wc->html2wiki($s); 
print $output_text . "\n";
