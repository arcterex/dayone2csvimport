#!/usr/bin/perl
use strict;
use HTML::WikiConverter;
use Text::CSV;
use Data::Dumper;

my @rows;
# open up the CSV
my $csv = Text::CSV->new ( { binary => 1 } )or die "Cannot use CSV: " . Text::CSV->error_diag();

# prep for HTML -> Markdown

my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
open my $fh, "<:encoding(utf8)", "entries.csv" or die "entries.csv: $!";

my $line = 0;
while ( my $row = $csv->getline( $fh ) ) {
	$line++;
	print "Line = $line\n";
#	print Dumper $row;
	print $wc->html2wiki( $row->[30] );
	print "\n-----\n";
	push @rows, $row;
	last if $line > 2;
}


print "Done\n";
