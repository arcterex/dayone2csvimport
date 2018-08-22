#!/usr/bin/perl
use strict;
use HTML::WikiConverter;
use HTML::TokeParser::Simple;
use HTML::Clean;
use Text::CSV;
use Data::Dumper;
use DateTime::Format::Strptime;

#### User Configuration
# What's the CSV file 
my $filename = "entries.csv";

# If you have html that just references pages (ie: <a href="foo.html">foo</a>) 
# this is the URL to use as a base for it in the html2wiki converter
my $base_url = "http://mysite.com";

# Give the CSV column numbers some names so addressing fields in the array is easier
# See the README.md file for more information about this and what these really mean.
my $id 							= 0;
my $title 						= 5;
my $authored_on 				= 10;
my $categories_secondary 	= 13;
my $convert_breaks 			= 15;
my $keywords 					= 22;
my $tags_list 					= 29;
my $text 						= 30;
my $text_more 					= 31;

# Debug 1 or 0 - currently doesn't do much
my $debug = 1;

# Are we doing this for real?  1 = no, 0 = yes
my $dryrun = 1;

# output the entry to the console?
my $output_to_console = 1;

# are we debugging the tags?
my $print_tags_to_console = 1;

# 0 for all, id number (not line) if you're looking for a specific entry
my $specific_entry = undef;

# debugging and only want to output X entries before stopping (empty = all, number = that number)
my $short_run = 0;

# maybe we want to do a range for the lines
my $line_range = {
	'start' => undef,
	'end'   => undef,
	};
# or entry ID range
my $id_range = {
	'start' => 0,
	'end'   => 2628,
	};

# Is there a default tag you want to add to each entry to identify the 
# imported entries somehow?
my $default_tag = "OldBlogEntry";

## Other system variables
# What's the Day One executable and path (if applicable)
my $dayoneexecutable = "dayone2";
# What journal are we putting the entries into?
my $journalname = 'Old Blog';

# Make sure that people know they're getting into a world of hurt using this
my $this_is_stupid = 0;
if( $this_is_stupid != 0 ){
	print <<'STUPIDSHIT';
I acknowledge that I understand this is not meant for anyone but the author 
and will probably blow all my shit up, and I'm going to remove this clause 
in the code ONLY when I understand what the hell I'm doing and why this is 
not a good idea at all.

Here there be dragons.

Seriously, don't do it.";
STUPIDSHIT

	die();
}

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
	image_style => 'inline',
	image_tag_fallback => 0,
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

# Set a counter for each line and each entry processed and failed
my $line = 0;
my $processed = 0;
my $failed = 0;

# Counter for formatting types
my $formatting;

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
	
	# NOTE: $line_range and $id_range don't really work together, 
	# one has to be undef if you're using the other
	# are we only doing a certain range?
	if( $line_range->{start} && $line_range->{end} ) 
	{
		if( $line < $line_range->{start} ) {
			next;
		}
		if( $line > $line_range->{end} ) {
			last;
		}
	}

	# or by id
	if( defined $id_range->{start} && defined $id_range->{end} ) 
	{
		if( $row->[$id] < $id_range->{start} ) {
#			print "$row->[$id] < $id_range->{start}\n";
			next;
		}
		if( $row->[$id] > $id_range->{end} ) {
			# in case the IDs are out of order don't just do a last() here
#			print "$row->[$id] > $id_range->{end}\n";
			next;
		}
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

	if( $output_to_console ) {
		print "DEBUG: INPUT\n---\n$input_text\n\n----\n";
	}
	#
	## Entry Text massaging
	#
	# First, to deal with keeping comments, which are important to me here,
	# substitute <!-- with [!-- and --> with --].  These will show up in the resulting markdown as is

	$input_text =~ s/<!--/[!--/g;
	$input_text =~ s/-->/--]/g;

	# Another thing that I need to clean up is that some entries in the original blog were set up 
	# with 'markdown_with_smartypants' or 'markdown' set for the convert_breaks field.  
	# If this is the case, we have to make sure we *don't* run the conversion.
	my $entry_is_markdown = 0;
	my $entry_is_default = 0;
	my $format = $row->[$convert_breaks];

	print "DEBUG: Entry ID $row->[$id] line $line formatting is $format ($row->[$convert_breaks])\n" if $debug;

	# keep count of how many of what
	$formatting->{$format}++;

	# we'll need some rules about what to do depending on the markup
	my $convert_html = 0;		# straight html
	my $convert_html_no_p = 0;	# html without <p> tags
	my $no_conversion = 0;		# markdown

	if( $format =~ /markdown/i ) 
	{
		$no_conversion = 1;
	} 
	elsif( $format =~ /__default_/i )  #some are __default__ and some are __default_
	{
		$convert_html_no_p = 1;
	} 
	elsif( $format =~ /richtext/i ) {
		$convert_html = 1;
	}
	elsif( $format eq "0" or $format eq "1" ) {
		$convert_html = 1;
	}
	elsif( $format eq "" ){
		$convert_html = 1;
	}
	else
	{
		print "DEBUG: Unknown formatting! $format\n";
	}


	## Clean the tags
	# Some of the entries have window pop up's in HTML - even if it's in Markdown
	# So we have to parse through the tags and:
	#  - remove the extra attributes from IMG tags
	#  - remove the a href onclick tags around IMG tags
	$input_text = clean_img_tags( $input_text );

	# now implement the formatting rules, no conversion, html, or html w/o <p> tags
	## HTML -> Markdown
	# convert from html to markdown if we need to
	if( $no_conversion == 1) 
	{
		print "DEBUG: Entry is Markdown - doing nothing\n" if $debug;
		$output_text = $input_text;

		if( $row->[$text_more] =~ /\S+/ ) {
			my $more_text = $row->[$text_more];
			$output_text .= "\n\n---\n" . $more_text;
		}
	} 
	elsif( $convert_html == 1 ) 
	{
		print "DEBUG: Entry is HTML - converting\n" if $debug;

		# Are there <UL> without a following <P> that need to be fixed?
		$input_text = fix_html_li($input_text);
		$input_text = fix_other_html($input_text);

		# do the HTML conversion
		$output_text = $wc->html2wiki( $input_text );

		if( $row->[$text_more] =~ /\S+/ ) {
			my $more_text = $row->[$text_more];
			$more_text = fix_html_li($more_text);
			$more_text = fix_other_html($more_text);
			$output_text .= "\n\n---\n" . $wc->html2wiki( $more_text );
		}
	}
	elsif( $convert_html_no_p == 1) {
		print "DEBUG: Entry ID $row->[$id] is HTML w/o <p> - add <p> and convert\n" if $debug;

		# Fix bad <P>
		my $temp_text = add_p_tags($input_text);

		# Fix bad <UL>
		$temp_text = fix_html_li($temp_text);
		$temp_text = fix_other_html($temp_text);

		# do the HTML conversion
		$output_text = $wc->html2wiki( $temp_text );

		# Add on extra text if there's something there
		# TODO - make this better handled
		if( $row->[$text_more] =~ /\S+/ ) {
			my $temp_more = $row->[$text_more];
			my $more_out = add_p_tags($temp_more);

			$more_out = fix_html_li($more_out);
			$more_out = fix_other_html($more_out);

			$output_text .= "\n\n---\n" . $wc->html2wiki( $more_out );
		}
		# Are there <UL> without a following <P> that need to be fixed?
	}

	# Also add in an <em> </em> there to emphasize it in the outputting marked up text as well
	# but we can't do this before since the only way it seems to get *emphasis* is if the stars
	# are right next to the words.  Luckily we can add literal HTML (<em>) in our just-converted 
	# markdown.  Kinda messed up but hey, it works.

	$output_text =~ s/\[!--/[!--<em>/g;
	$output_text =~ s/--\]/<\/em>--]/g;

	# and fix <br />'s
#	print "fixing <BR>\n";
#	$output_text =~ s/<br \/>/<br>/g;
#	print "done fixing <BR>\n";

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

	# ... and the categories as well
	my @categories_list_array = split /\s*,\s*/, $row->[$categories_secondary];


	# load everything into the tags array
	my @outtags = (@tags, @tag_list_array, @keyword_list_array, @categories_list_array);

	# Make sure the tags are all unique
	my %seen =() ;
	my @unique_outtags = grep { ! $seen{$_}++ } @outtags ;
	@outtags = @unique_outtags;

	# Now create the string from the array
	my $output_tags = "";

	# For the CLI we need to replace any spaces in the tags with "\ " 
	# so #foo #bar baz turns in "foo bar\ baz"
	my $cli_output_tags = "";

	foreach( @outtags ) { 
		$output_tags .= "#$_ ";
		# now deal with tags for the command line
		my $cli_tag = $_;

		# do substitution only if the tag has a space in it
		if( $_ =~ /\S\s\S/) { 
			$cli_tag =~ s/\s/\\ /g;
		}

		$cli_output_tags .= $cli_tag . " ";
	}

	# trim whitespace from both sides
	$cli_output_tags =~ s/^\s+|\s+$//g;
	if( $print_tags_to_console ) { 
		print "DEBUG: Tags list: '$cli_output_tags'\n"; 
	}

	#### Final entry creating
	# Now create the entry from the template that we got from Day One
	my $entry = <<END;
$output_title
$output_text
END

	if( $output_to_console ) {
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
			print "Successfully created entry for line $line ('" . $row->[$id] . " / $output_title' / $output_date_time)\n";
			$processed++;
			if( $debug ) { print "DEBUG: $output\n"; }
		} else {
			# ERROR!!
			$failed++;
			die "Error creating entry :( \n$output\n\n";
		}

		# finally remove the file
		unlink $filename;
	} 
	else {
		print "Dry run, not creating day one entry for line $line (id: " . $row->[$id] . " / '$output_title')\n";
	}

	# For testing we can stop at a certain point to check the results or do a test import
	if( $short_run ) {
		last if $line > $short_run;
	}
}
### Done!!!

# Clean input by removing extra attributes from img tags as well as 
# removing the a href onclick surrounding an img tag
sub clean_img_tags
{
	my $input = shift;
	my $cleaning = $input;
	my $cleaned = "";
	my $output = "";

	# Now modify the cleaned text and use a regex to replace:
	# <a href onclick=.*><img.*></a>
	# with
	# <img.*>
	$cleaning =~ s/<a href=.*?>(<img.*?>)<\/a>/$1/g;

	# Now clean up the IMG tag
	my $parser = HTML::TokeParser::Simple->new( string => $cleaning );

	# clean up the image tag
	while( my $token = $parser->get_token ) {
		if( $token->is_tag('img')) {
			$token->delete_attr('width');
			$token->delete_attr('height');
#			$token->delete_attr('alt');
			$token->delete_attr('class');
			$token->delete_attr('style');
		}

		$cleaned .= $token->as_is;
	}

	$output = $cleaned;
	
	return $output;
}

# We need to wrap the incoming text so that empty lines are replaced with </p><p>
sub add_p_tags
{
	my $wc2 = new HTML::WikiConverter( 
			base_uri 	=> $base_url,
			dialect => 'Markdown',
			link_style  => 'inline',
			image_style => 'inline',
			base_uri    => $base_url,
			image_tag_fallback => 0,
			escape_entities => 1,
			md_extra => 1,
		);
	my $incoming_text = shift @_;
	# magic from https://www.perlmonks.org/?node_id=591605
	$incoming_text =~ s/(?!^<p>)([\r\n]){2,}/\n<p>\n/g;

	return $incoming_text;
}

# This will fix the errors where the end of a list item is combined with
# the text from the next line.
# We want to add two \n's between the </ul> if there's only one
sub fix_html_li
{
    my $input = shift @_;

    # if it has a <ul> without newlines, add them
	 print "DEBUG: Checking for un-ended list\n" if $debug;
    if( $input =~ /(<\/ul>+\r?\n)+(?=(\r?\n)?)/gmi ) {
        print "DEBUG: Found un-ended list\n" if $debug;
        $input =~ s/(<\/ul>+\r?\n)+(?=(\r?\n)?)/<\/UL>\n<p>\n/gmi;
    }

    return $input;

}

# Other misc fixes for bad html
sub fix_other_html
{
	print "DEBUG: Fixing other HTML\n" ;
	my $input = shift @_;
	
	# Also replace two <BR>'s on a line with a <p>
	$input =~ s/<br><br>/<p>/ig;

	# And fix <EM> on a line of it's own
	$input =~ s/<EM>\s+(\S)/<EM>$1/igm;

	# and the other end of the </EM>
	if( $input =~ /(\S)\s+<\/EM>/igm ) {
		print "Found a lost </EM>";
		$input =~ s/(\S)\s+<\/EM>/$1<\/EM>/igm;
	}

	# Add a </P> before any <blockquote>'s to make sure the > goes on a new line
	# Multiple preceeding </P> tags don't seem to matter after the markdown conversion
	$input =~ s/(<blockquote>)/<\/P>\n$1/gim;

	print "DEBUG: Fixed HTML OUTPUT:\n-------\n" if $debug;
	print $input;
	return $input;
}

## NOTE: if you uncomment these remmeber they'll be at the end of your last imported entry
print "\n\n--------------\n";
print "Done!\n";
print "Successful       = $processed\n";
print "Failed :(        = $failed\n";
print "Total inputs     = $line\n";
print "\n";
