#!/usr/bin/perl
use strict;
use HTML::WikiConverter;
use Text::CSV;
use Data::Dumper;
use DateTime::Format::Strptime;

my @rows;
# open up the CSV
my $csv = Text::CSV->new ( { 
		binary => 1,
		quote_space => 0,
#		auto_diag => 9,
#		diag_verbose => 2,
		allow_loose_quotes => 1,
		allow_loose_escapes => 1,
		allow_unquoted_escape => 1,
	} ) or die "Cannot use CSV: " . Text::CSV->error_diag();

# prep for HTML -> Markdown

my $wc = new HTML::WikiConverter( dialect => 'Markdown', link_style => 'inline' );
open my $fh, "<:encoding(utf8)", "entries.csv" or die "entries.csv: $!";

my $ok = 0;
my $total = 0;

while( my $line = <$fh> ){
	chomp $line;
	$total++;
	if( $csv->parse($line) ) {
		my @fields = $csv->fields();
		$ok++;
		print "OK $ok\n";
	} else {
		warn "Line could not be parsed $line\n";
	}
	last if ($total > 10);
}

print "Parsed $ok of $total\n";
