#!/usr/bin/perl
use strict;
use HTML::WikiConverter;
use Text::CSV;
use Data::Dumper;
use DateTime::Format::Strptime;

=pod
## TODO ##
 - Does markdown do underlines? - NO
 - Some entries don't have <P> and it's fucking up *some* entries
 - Have to go in manually to fix the <tt><pre> code and convert it to code ```xxx``` in markdown after the fact
 - Have to do a spot check and fix some <dl><dd> -> quote blocks, missing images, and some formatting issues
 	that have resulted from converting code to colorful code (but that is converted into markdown which doesn't 
	work

# About 
This is a very custom perl script to do the singlular job of converting a CSV from 
a decade old Movable Type blog into a format that can be import into Day One as per 
their plain text import as per http://help.dayoneapp.com/settings/importing-data-to-day-one

## My Very Specific Set of Circumstances
This is from:

 - A Movable Type 5.2.2 install
 - The [Entry CSV Export](https://plugins.movabletype.org/entry-csv-export/) plugin installed
 	and with the site exported from there
 - The CSV file called entries.csv
 - Various idiosyncrasies of the export - extra whitespace in the tags, random extra characters 
 	around titles, etc 
 - Importing into Day One 2.7.4 (current version as of 2018-08-07) running on macOS
 - I did a lot of programming in perl from 1998 to 2011 or so, meaning I know how to program
 	but haven't for a while, and am missing a lot of the more elegant ways of doing things
	that I just don't want to be bothered to do

This can be a template if you're a perl programmer from the early '00s to modify to use with 
your own CSV data to import from CSV to Day One by doing some fiddling


## Stuff you'll need to change if you're not me

This is the structure of the CSV export I'm working with.  The columns are as follows:

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

Only some of these are interesting, so most can be ignored.  In theory you can simply change the numbers
that are used to address the fields and then it can use *your* CSV format.

Currently the script exports to STDOUT, so you'd run it as:

$ ./convert.pl > entries.txt

The output format that will be spit out for each entry in the CSV file:

<tab>Date:	June 24, 2016 at 10:59:06 AM MDT

Title
Text

#tags

<tab>Date:....

## User editable stuff

 - There is a 'user configuration data' set of variables, modify things there
 	- filename
	- column numbers for the fields that Day One cares about

=cut

#### User Configuration
# What's the CSV file 
my $filename = "entries.csv";

# If you have html that just references pages (ie: <a href="foo.html">foo</a>) 
# this is the URL to use as a base for it in the html2wiki converter
my $base_url = "http://arcterex.net";

# Give the CSV column numbers some names so addressing fields in the array is easier
my $id 					= 0;
my $title 				= 5;
my $authored_on 		= 10;
my $convert_breaks 	= 15;
my $keywords 			= 22;
my $tags_list 			= 29;
my $text 				= 30;
my $text_more 			= 31;

# Debug 1 or 0 - currently doesn't do much
my $debug = 1;

# Are we doing this for real?  1 = no, 0 = yes
my $dryrun = 1;

# output the entry to the console?
my $output_to_console = 1;

# looking for a specific id for the entry?
my $specific_entry = 4315;

# debugging and only want to output X entries before stopping (empty = all, number = that number)
my $short_run = "10";


# Is there a default tag you want to add to each entry to identify the 
# imported entries somehow?
my $default_tag = "OldBlogEntry";

# Other system variables
my $dayoneexecutable = "dayone2";
my $journalname = 'Old Blog';

#### Create the parsing objects
# Create the CSV parser that will be fed the input file filehandle 
my $csv = Text::CSV->new ( { 
		binary 		=> 1,
		quote_space => 0,
		auto_diag 	=> 9,
		decode_utf8 => 1,
	} ) 
	or die "Cannot use CSV: " . Text::CSV->error_diag();

# Create the HTML -> Markdown converter
my $wc = new HTML::WikiConverter( 
	dialect 		=> 'Markdown', 
	link_style 	=> 'inline',
	base_uri 	=> $base_url,
	);

# Create the date time parser
my $parser = DateTime::Format::Strptime->new(
	pattern 		=> '%F %T',
	on_error 	=> 'croak',
	time_zone 	=> 'Canada/Pacific',
);

# Open the file and reference it with a filehandle
open my $fh, "<:encoding(utf8)", $filename or die "$filename: $!";

# Set a counter for each line
my $line = 0;

# First read first line so we don't try to read the headers
my $header = <$fh>;

# Now loop through the CSV file
while ( my $row = $csv->getline( $fh ) ) 
{
	$line++;

	# are we debugging and only looking for a specific entry?
	if( $specific_entry ) { 
		next if( $row->[$id] ne $specific_entry );
		print "DEBUG: Only printing entry ID #$specific_entry\n" if $debug;
	}

	# Error checking if something went wrong
	if( $csv->error_diag() ) {
		print "Error\n";
	}
	# or if the row didn't read for some reason
	die if not $row;

	#### Date
	# In my case the incoming date time string is:
	# 1996-11-03 12:24:44
	# and we need to convert it to this format:
	# June 24, 2016 at 10:59:06 AM MDT

	my $entry_date_time = $row->[$authored_on];

	# Load it into a DateTime object (amazingly this parses it properly)
	my $dt = $parser->parse_datetime($entry_date_time);

	# Turn it into the expected date format noted above
	my $output_date_time = $dt->strftime("%b %d, %Y at %l:%M:%S %p %Z");

	#### Title
	my $in_output_title = $row->[$title];

	# A bunch of titles in the CSV they look like:
	# Title: ="07/31/2000"
	# Title: ="08/01/2000"
	# Title: ="08/01/2000 2"
	# Title: ="08/07/2000"
	# Title: ="08/09/2000"
	# I need to parse out what's in between =" and ", but this only happens
	# if the string matches ="something"
	$in_output_title =~ s/^=\"(.*)\"$/$1/;
	my $output_title = $in_output_title;

	# Run the title through html2wiki to deal with HTML in the title
	$output_title = $wc->html2wiki( $in_output_title );

	#### Entry Text
	my $output_text; 
	my $input_text = $row->[$text];

	#
	## Entry Text massaging
	#
	# First, to deal with keeping comments, which are important to me here,
	# substitute <!-- with [!-- and --> with --].  These will show up in the resulting markdown as is

	$input_text =~ s/<!--/[!--/g;
	$input_text =~ s/-->/--]/g;

	# Another thing that I need to clean up is that some entries in the original blog were set up 
	# with 'markdown_with_smartypants' or 'markdown' set for the convert_breaks field.  
	# If this is the case, we
	$input_text =~ s/(^|\n)[\n\s]*/\n<\/p>$1<p>\n/g;

	## HTML -> Markdown
	# convert from html to markdown
	$output_text = $wc->html2wiki( $input_text );

	# If there's something in the 'text_more' colume add it after
	# I believe none of my entries have the text_more, but if they do, this deals with it
	if( $row->[$text_more] ne "" ) {
		$output_text .= "\n\n" . $wc->html2wiki( $row->[$text_more] );
	}

	# Also add in an <em> </em> there to emphasize it in the outputting marked up text as well
	# but we can't do this before since the only way it seems to get *emphasis* is if the stars
	# are right next to the words.  Luckily we can add literal HTML (<em>) in our just-converted 
	# markdown.  Kinda messed up but hey, it works.

	$output_text =~ s/\[!--/[!--<em>/g;
	$output_text =~ s/--\]/<\/em>--]/g;

	# and fix <br />'s
	$output_text =~ s/<br \/>/<br>/g;



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

	# For the CLI we need to replace any spaces in the tags with "\ " 
	# so #foo #bar baz turns in "foo bar\ baz"
	my $cli_output_tags = "";

	my $foo = 0;
	foreach( @outtags ) { 
		$output_tags .= "#$_ ";
		# now deal with tags for the command line
		my $cli_tag = $_;

		# do substitution only if the tag has a space in it
		if( $_ =~ /\S\s\S/) { 
			$cli_tag =~ s/\s/\\ /g;
			$foo = 1;
		}

		$cli_output_tags .= $cli_tag . " ";
	}

	# trim whitespace from both sides
	$cli_output_tags =~ s/^\s+|\s+$//g;
	if( $foo == 1 ) { print "'$cli_output_tags'\n"; }

	#### Final entry creating
	# Now create the entry from the template that we got from Day One
	my $entry = <<END;
$output_title
$output_text
END

	if( $output_to_console ) {
		print "DEBUG: INPUT\n---\n$input_text\n\n----\n";
		print "DEBUG: OUTPUT\n---\n$entry\n\n----\n";
	}

	# If we're doing this for real, create the files and run the command to import them
	if( !$dryrun ) 
	{
		# Create a file to write this to
		my $filename = "entry-$line.txt";
		open( my $fh, '>', $filename ) or die("Can't open file: $filename - $!");

		#### Output the entry to a file (or somewhere else if you write it to a file)
		print $fh $entry;

		# Close the file
		close $fh;

		# finally call the dayone2 command on the command line with arguments for the date, tags, etc
		my $command = "cat $filename | $dayoneexecutable --journal \"$journalname\" --date='$output_date_time' --tags $cli_output_tags -- new";

		my $output = `$command`;
		if( $output =~ /Created new entry with uuid/ ) {
			print "Successfully created entry $line ($output_date_time)\n";
			if( $debug ) { print "DEBUG: $output\n"; }
		} else {
			# ERROR!!
			die "Error creating entry :( \n$output\n\n";
		}

		# finally remove the file
		unlink $filename;
	} 
	else {
		print "Dry run, not creating day one entry for line $line\n";
	}

	# For testing we can stop at a certain point to check the results or do a test import
	if( $short_run ) {
		last if $line > $short_run;
	}
}

### Done
## NOTE: if you uncomment these remmeber they'll be at the end of your last imported entry
print "Done!\n";
print "Processed $line entries\n\n";
