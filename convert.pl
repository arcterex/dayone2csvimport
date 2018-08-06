#!/usr/bin/perl
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

my @rows;
# open up the CSV
my $csv = Text::CSV->new ( { 
		binary => 1,
		quote_space => 0,
		allow_loose_quotes => 1,
		allow_loose_escapes => 1,
		allow_unquoted_escape => 1,
		always_quote => 1,
	} ) or die "Cannot use CSV: " . Text::CSV->error_diag();


# prep for HTML -> Markdown

my $wc = new HTML::WikiConverter( dialect => 'Markdown', link_style => 'inline' );
open my $fh, "<:encoding(utf8)", "entries.csv" or die "entries.csv: $!";

# let's make some aliases so addressing fields in the array is easier
my $text = 30;
my $text_more = 31;
my $title = 5;
my $authored_on = 10;
my $keywords = 22;
my $tags_list = 29;

my $more_count = 0;

my $errors = 0;
my $debug = 0;

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
#while ( my $row = $csv->getline( $fh ) ) {
while( my $line = <$fh>) {
	next if( $. == 1); # skip the first line

	if( my $parsed_line = $csv->parse($line)) {
		my @fields = $csv->fields();
	} else {
		my $err = $csv->error_input;
		print "Failed to parse line: $err\n\n-----\n";
		$csv->error_diag ();
		print "\n\n---\n" . Dumper $line . "\n--\n" . Dumper $parsed_line . "\n\n";
		$errors++;
	}
=pod
	my $row = $csv->parse();

	# Error checking for bad line
	unless( $row ) {
		my @diag = $csv->error_diag;
		print Dumper @diag;
	}
	print Dumper $row if $debug;

	# Get the date
	# Incoming date time string is:
	# 1996-11-03 12:24:44

	my $entry_date_time = $row->[$authored_on];
#	print "Datetime: $entry_date_time\n";
	my $dt = $parser->parse_datetime($entry_date_time);

	# Turn it into :
	# Date:  June 24, 2016 at 10:59:06 AM MDT
	my $output_date_time = $dt->strftime("%b %d, %Y at %l:%M:S %p %Z");

#	print "Date:  $entry_date_time | ";
#	print "$output_date_time\n";

	# Get the title
	my $output_title = $row->[$title];

	# for a bunch of titles the CSV they look like:
	# Title: ="07/31/2000"
	# Title: ="08/01/2000"
	# Title: ="08/01/2000 2"
	# Title: ="08/07/2000"
	# Title: ="08/09/2000"
	# so I need to parse out what's in between ="xxx"
	$output_title =~ s/^=\"(.*)\"$/$1/;
#	print $output_title . "\n";

	print $csv->status();

	# Get the text
	my $text;
	$text = $wc->html2wiki( $row->[$text] );
	# if there's something in the 'text_more' colume add it after
	if( $row->[$text_more] ne "" ) {
		$text .= "\n\n" . $wc->html2wiki( $row->[$text_more] );
	}

	# Get the tags
	print $row->[$tags_list] if $debug;
	
	print "\n-----\n" if $debug;
	push @rows, $row;
	last if $. > 905;
=cut
}

print "Errors $errors\n";
print "Done\n";
