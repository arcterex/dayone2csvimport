# Import to Day One 2 From CSV

## Warning
Don't use this.  **Seriously**, don't.  This is a completely custom solution to a problem
almost no one has.  I've made it fairly editiable, with flags and names and some 
generalizations.  In theory someone could adapt it to work with generic CSV files, but 
other than using this as a framework to use to start, it's not going to be good for much.

Other things that are wrong: 
 - no one programs in perl anymore
 - no one uses Movable Type anymore
 - there are almost no functions in this script
 - this was started out to be a 20 line "iterate through CSV, output file" script that grew 
 	into this monstrosity
 - The way that setting base\_uri in HTML::WikiConverter::Markdown v0.68 seems to be wrong.  I've had
 	to patch this file (in version 0.68 add a line to return $uri right after line 518 in 
	\_abs2url() before the check for $self->base_uri) to make sure that relative URLS (/foo.html)
	are converted properly to absolute URLs (server.com/foo.html) when the links are converted
	in markdown.  I have filed a bug

## About 
This is a very *very* custom perl script to do the singlular job of converting a CSV from 
a decade old Movable Type blog into a format that can be import into the Mac and iOS journalling 
app Day One via their [cli interface](http://help.dayoneapp.com/tips-and-tutorials/command-line-interface-cli)

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

## Prerequisits
 - Day One 2 installed
 - The Day One 2 [cli tools](http://help.dayoneapp.com/tips-and-tutorials/command-line-interface-cli) installed
 - Perl running
 - Perl modules:
 	- HTML::WikiConverter
	- HTML::Clean
	- HTML::TokenParser::Simple
	- Text::CSV
	- DateTime::Format::Strptime

## Stuff you'll need to change if you're not me

This is the structure of the CSV export I'm working with.  The columns are as follows:

```
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
```

Obviously your particular CSV file will be different.

Only some of these are interesting, so most can be ignored.  In the main program there's a selection 
of variables that mach up to the various fields here.  So to get the ID text instead of addressing
$row->[30] you'd set $id to 30 and then address $row->[$id].  Of course a real programmer would turn
each row into it's own object and address it as $row->id, but this is not what I'm doing here.

You would simply change the numbers that are used to address the fields and then it can use *your* 
CSV file's fields.

There are various flags towards the top of the script that are self-documenting, things like
$dryrun and $output\_to\_console.

## Basic structure

This all started pretty simply:

 - Load CSV data
 - Loop through data
 	- Collect entry data
	- Massage entry data
	- Write entry to Day One
 - End loop

When the data is ready, it's written to Day One by outputting to a text file 
in the form of (<line-number>.txt) and then a shell command is run:

```
$ cat <file> | dayone2 --journal <name of journal> --date='<the date>' --tags <list of tags> -- new";
```

The file is then removed and the next entry is read, massaged, and output.

The text that is in the file is simply the title, a newline, and then the entry data.  Tags and date 
are entered by the command line.  Location isn't dealt with at all, and nor are photos.

## User editable stuff

 - There is a 'user configuration data' set of variables, modify things there
 	- filename
	- column numbers for the fields that Day One cares about

# What This Script Will NOT DO
## Errors, failures, and cleanup

As I have found working with this, the script gets you about 80% of the way there.  It doesn't 
make sense to spend hours working on edge cases for what can be considered a waste of time already,
so once this is run and the data is imported, you'll still have to go through and do cleanup on 
the various entries for things such as:

 - converting <img> HTML tags that reference images online to dragging the actual images in so they 
   are "native" images in Day One
 - formatting needs cleaning still.  I've found errant \<br /\>'s, and some formatting such as 
 	nested \<tt\> and \<blockquote\> tags to create an HTML aware console display don't work.  I 
	haven't found a way to get Markdown to let me do this (I want a code block that will interpret
	some markup, such as \*\*bold\*\*).
 - Overall spot check.  This does a good job to get the bulk of your data in there, but if you 
 	are concerned about it being **right** you'll need to go through each entry and at least give 
	it a cursory look to make sure it's not completely blown up
 - Fix any HTML that's *very* HTML-ized.  For example at some point I used a program that would
 	color code code with html... worked great on a web page, with colored variables, formatting,
	etc, but that doesn't come back across into Day One all that well. 
