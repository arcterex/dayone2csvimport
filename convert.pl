#!/usr/bin/perl
use strict;
use HTML::WikiConverter;
use Text::CSV;
use Data::Dumper;

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
10          'authored_on',
11          'blog_id',
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
my $csv = Text::CSV->new ( { binary => 1 } )or die "Cannot use CSV: " . Text::CSV->error_diag();

# prep for HTML -> Markdown

my $wc = new HTML::WikiConverter( dialect => 'Markdown', link_style => 'inline' );
open my $fh, "<:encoding(utf8)", "entries.csv" or die "entries.csv: $!";

my $line = 0;
my $more_count = 0;
while ( my $row = $csv->getline( $fh ) ) {
	$line++;
	print "Line = $line\n";
	print Dumper $row;
	print $wc->html2wiki( $row->[30] );
	# if there's something in the 'text_more' colume add it after
	if( $row->[31] ne "" ) {
		print $wc->html2wiki( $row->[31] );
		$more_count++;
	}
	print "\n-----\n";
	push @rows, $row;
	last if $line > 2;
}

print "Entries: $line\n";
print "More: $more_count\n";
print "Done\n";
