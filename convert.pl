#!/usr/bin/perl
# TODO:
# base URL

use strict;
use HTML::WikiConverter;
use Text::CSV;
use Data::Dumper;
#use Date::Format;
#use Date::Parse;
use DateTime::Format::Strptime;

=pod
Structure of each entry:

$VAR1 = [
0          'id',
1          'blog_name',
2          'basename',
3          'status_as_text',
4          'edit_url',
5          'title',
6          'allow_comments',
7          'allow_pings',
8          'atom_id',
9          'author_id',
10         'authored_on',
11         'blog_id',
12         'categories_secondary',
13         'category_label',
14         'class',
15         'convert_breaks',
16         'created_by',
17         'created_by_author',
18         'created_on',
19         'current_revision',
20         'excerpt',
21         'junk_log',
22         'keywords',
23         'modified_by',
24         'modified_by_author',
25         'modified_on',
26         'permalink',
27         'revision',
28         'status',
29         'tags_list',
30         'text',
31         'text_more',
32         'week_number'
        ];


=cut

# open up the CSV
my $csv = Text::CSV->new ( { 
		binary => 1,
		quote_space => 0,
#		auto_diag => 9,
		decode_utf8 => 1,
	} ) or die "Cannot use CSV: " . Text::CSV->error_diag();

# prep for HTML -> Markdown
my $wc = new HTML::WikiConverter( 
	dialect 		=> 'Markdown', 
	link_style 	=> 'inline',
	base_uri 	=> 'http://arcterex.net',
	);

# Load up the file
open my $fh, "<:encoding(utf8)", "entries.csv" or die "entries.csv: $!";

# let's make some aliases so addressing fields in the array is easier
my $text = 30;
my $text_more = 31;
my $title = 5;
my $authored_on = 10;
my $keywords = 22;
my $tags_list = 29;

my $line = 0;
my $more_count = 0;

my $debug = 0;

# User Configuration Section
my $default_tag = "OldBlogEntry";

=pod 
Output Format:

<tab>Date:	June 24, 2016 at 10:59:06 AM MDT

Title
Text

#tags

<tab>Date:....

=cut
# date time parser
my $parser = DateTime::Format::Strptime->new(
	pattern => '%F %T',
	on_error => 'croak',
	time_zone => 'Canada/Pacific',
);

# load first line so we don't try to read the headers
my $header = <$fh>;

# Loop through the CSV file
while ( my $row = $csv->getline( $fh ) ) {
	$line++;
	

	# Error checking if something went wrong
	if( $csv->error_diag() ) {
		print "Error\n";
	}
	# or if the row didn't read for some reason
	die if not $row;

	#### Date
	# Incoming date time string is:
	# 1996-11-03 12:24:44
	my $entry_date_time = $row->[$authored_on];

	# Load it into a DateTime object
	my $dt = $parser->parse_datetime($entry_date_time);

	# Turn it into the expected date format:
	# Date:  June 24, 2016 at 10:59:06 AM MDT
	my $output_date_time = $dt->strftime("%b %d, %Y at %l:%M:%S %p %Z");

	#### Title
	my $in_output_title = $row->[$title];

	# A bunch of titles in the CSV they look like:
	# Title: ="07/31/2000"
	# Title: ="08/01/2000"
	# Title: ="08/01/2000 2"
	# Title: ="08/07/2000"
	# Title: ="08/09/2000"
	# so I need to parse out what's in between ="xxx"

	$in_output_title =~ s/^=\"(.*)\"$/$1/;
	my $output_title = $in_output_title;

	# Finally run the title through html2wiki to deal with HTML in the title
	$output_title = $wc->html2wiki( $in_output_title );

	#### Entry Text
	my $output_text;
	# convert from html to markdown
	$output_text = $wc->html2wiki( $row->[$text] );
	
	# If there's something in the 'text_more' colume add it after
	# I believe none of my entries have the text_more, but if they do, this deals with it
	if( $row->[$text_more] ne "" ) {
		$output_text .= "\n\n" . $wc->html2wiki( $row->[$text_more] );
	}

	#### Tags and Keywords
	# Movable type has the concept of both "tags" and "keywords".  I'm going to convert
	# all of them into the #tags that DayOne supports
	# Things to deal with is that some of the output has extra leading/trailing spaces,
	# and some tags have spaces in them, so we can't just remove all whitespace but have to 
	# split into arrays on ',' and remove only leading and trailing whitespace

	# Load the array with the default tag
	my @tags = ($default_tag);

	# turn the tags list string into an array
	my @tag_list_array = split /\s*,\s*/, $row->[$tags_list];

	# ... and the keywords as well
	my @keyword_list_array = split /\s*,\s*/, $row->[$keywords];

	# load everything into the tags array
	my @outtags = (@tags, @tag_list_array, @keyword_list_array);

	# Now create the string from the array
	my $output_tags = "";
	foreach( @outtags ) { 
		$output_tags .= "#$_ ";
	}

	#### Final entry creating
	# Now print off the entry:
	my $entry = <<END;
	Date:	$output_date_time

$output_title
$output_text

$output_tags

END
	# and we're done, lets do the next one
}
