#!/usr/bin/perl -w 
#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.

#
# NOTE TO DEVELOPERS: Use "XXX" to mark bugs or areas that need work
# use something like this to find how many things need work:
# find . | grep -v CVS | xargs grep XXX | wc -l
#

#
# $Id: FormMagick.pm,v 1.37 2001/02/23 22:34:42 skud Exp $
#

package    FormMagick;
require    Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw(new display);

my $VERSION = $VERSION = "0.2.0";

use strict;
use Carp;

use XML::Parser;
use Text::Template;
use CGI::Persistent;
use FormMagick::TagMaker;

# Figure out what language we're using

use FormMagick::L10N;
my $language = FormMagick::L10N->get_handle()
        || die "Can't find an acceptable language module.";

=pod 

=head1 NAME

FormMagick - easily create CGI form-based applications

=head1 SYNOPSIS

  use FormMagick;

  my $f = new FormMagick();
  my $f = new FormMagick(TYPE => FILE,  SOURCE => $myxmlfile, DEBUG => 1);

  $f->add_lexicon("fr", { "Yes" => "Oui", "No" => "Non"});

  $f->display();

=head1 DESCRIPTION

FormMagick is a toolkit for easily building fairly complex form-based
web applications.  It allows the developer to specify the structure of a
multi-page "wizard" style form using XML, then display that form using
only a few lines of Perl.

=head2 How it works:

You (the developer) provide at least:

=over 4

=item *

Form descriptions (XML)

=item *

HTML templates (Text::Template format) for the page headers and footers

=back

And may optionally provide:

=over 4

=item *

L10N lexicon entries 

=item *

Validation routines for user input data

=item *

Routines to run before or after a page of the form is displayed

=back

FormMagick brings them all together to create a full application.

=head1 METHODS

=head2 new()

The C<new()> method requires no arguments, but may take the following
optional arguments (as a hash):

=over 4

=item TYPE

Defaults to "FILE" (the only currently implemented type).  Eventually
we'll also allow such things as FILEHANDLE, STRING, etc (c.f.
Text::Template, which does this quite nicely).

=item SOURCE

Defaults to a filename matching that of your script, only with an
extension of .xml (we got this idea from XML::Simple).

=item DEBUG

Defaults to 0 (no debug output).  Setting it to 1 (or any other true
value) will cause debugging messages to be output.

=back

=cut

sub new {
  shift;
  my $self 		= {};
  my %args 		= @_;

  my $p = new XML::Parser (Style => 'Tree');
  $self->{debug} = $args{DEBUG} || 0;


  if ($args{SOURCE}) {
    $self->{source} = $args{SOURCE};
  } else {
    # default source filename to the same as the perl script, with .xml 
    # extension
    use File::Basename;
  
    my($scriptname, $scriptdir, $extension) =
       File::Basename::fileparse($0, '\.[^\.]+');
  
    my $string = $scriptname . '.xml';
    $self->{source} = $string;
  }

  $self->{xml} = $p->parsefile($self->{source});

  # okay, this XML::Parser data structure is a little strange. 
  # perldoc XML::Parser gives some help, but here's a crib sheet: 
  
  # $self->{xml}[0] is "form", the name of the root element,
  # $self->{xml}[1] is the actual contents of the "form" element.
  # $self->{xml}[1][0] is the attributes of the "form" element.
  # $self->{xml}[1][4] is the first page. 
  # $self->{xml}[1][8] is the second page.
  # $self->{xml}[1][8][4] is the first field of the second page.  

  # debugging statements, use these to figure out for yourself 
  #   how the parse tree works. 
  # use Data::Dumper;
  # print Dumper( $self->{xml}) ;
  # print Dumper( $self->{xml}[1][0]) ;
  # print Dumper( $self->{current_page} );
  
  bless $self;
  return $self;

}

#----------------------------------------------------------------------------
# display()
#
# Displays the current form page
#----------------------------------------------------------------------------

=pod

=head2 display()

The display method displays your form.  It takes no arguments.

=cut

sub display {
  my $self = shift;

  # use the session-tokens/ directory to store session tokens
  use File::Basename;

  my($scriptname, $scriptdir, $extension) =
    File::Basename::fileparse($0, '\.[^\.]+');

  my $cgi = new CGI::Persistent "$scriptdir/session-tokens";
  print $cgi->header;

  # debug thingy, to check L10N lexicons, only if you need it
  check_l10n($self) if $cgi->param('checkl10n');

  # pick up page number from CGI, else default to 1
  my $pagenum = $cgi->param("page") || 1;

  # multiply page number by 4 to get the array index of where the page
  # description is... yes, it's ugly, but that's just how the parse tree
  # is with XML::Parser

  # find out about the last page submitted, so we can validate.

  $self->{current_page} = $self->{xml}[1][ $pagenum*4 ];

  # only go next/previous if there are no validation errors... if there
  # are validation errors, we want to redisplay the same page

  my %errors;

  # only validate if we got a form submitted. 
  if ($cgi->param("page"))  {
      %errors = validate_input($self, $cgi);
  } 

  unless (%errors) {

      if ($cgi->param("wherenext")) {
	  # do whatever we need to with the validated results of the old page
	  page_post_event($self, $cgi); 

	  # increment/decrement pagenum if the user clicked "Next" or "Previous"
          # or, if the user has explicitly set the "wherenext" param as
	  # the result of a post_event or something (eg checking user
	  # input to see what page to display next), find the page
	  # number by passing the NAME attribute of the PAGE element to
	  # the find_page_by_name() routine

	  if ($cgi->param("wherenext") eq "Next") {
	    $pagenum++ if $cgi->param("wherenext") eq "Next";
          } elsif ($cgi->param("wherenext") eq "Previous") {
	    $pagenum-- if $cgi->param("wherenext") eq "Previous";
          } elsif ($cgi->param("wherenext") eq "Finish") {
            # nothing! (see below)
          } else { 
            $pagenum = find_page_by_name($self, $cgi->param("wherenext"));
          }
	  
	  # re-set the current page, we incremented $pagenum
	  $self->{current_page} = $self->{xml}[1][ $pagenum*4 ];

	  # prepare for the new page.
	  page_pre_event($self, $cgi); 
      }
  }

  # The form pre-event needs not to run if we hit "Previous" to get to page 1.
  # XXX This still isn't working. Are we *sure* that putting two "wherenext" fields
  # (Next, Previous) on a page results in $cgi getting only the value of the one
  # that's submitted?

  form_pre_event($self, $cgi) 
      if (($pagenum == 1) && ($cgi->param("wherenext") eq "Previous"));
  
  # print out the templated headers (based on what's specified in the
  # HTML) then an h1 containing the FORM element's TITLE attribute
   
  print parse_template($self->{xml}[1][0]->{HEADER});
  print "<h1>", localise($self->{xml}[1][0]->{TITLE}), "</h1>\n";

  form_post_event($self, $cgi) if ($cgi->param("wherenext") &&
  	$cgi->param("wherenext") eq "Finish");

  print_page_header($self);

  # we print error messages below the headings
  # XXX it would be cool if this could happen near the field itself
  list_error_messages(%errors) if %errors;

  # here we figure out the submission URL and generate the HTML <FORM>
  # tag
  my $url = $cgi->url();
  print qq(<form method="POST" action="$url">\n);

  print qq(<input type="hidden" name="page" value="$pagenum">\n);
  print $cgi->state_field(), "\n";	# hidden field with state ID

  print "<table>\n";
  
  # we iterate through the fiels using the display_fields() routine
  display_fields($self, $cgi);

  print_buttons($self, $pagenum);

  print $cgi->state_field();

  print "</table>\n</form>\n";

  # here's how we clear our state IDs
  print qq(<p><a href="$url">Start over again</a></p>);

  # this is for debugging purposes
  debug($self, qq(<a href="$url?checkl10n=1">Check L10N</a>));

  print parse_template($self->{xml}[1][0]->{FOOTER});

}

#----------------------------------------------------------------------------
# print_buttons($self, $pagenum)
#
# print the table row containing the form's buttons
#----------------------------------------------------------------------------

sub print_buttons {
  my ($self, $pagenum) = @_;	
  print qq(<tr><td></td><td class="buttons">);
  print qq(<input type="submit" name="wherenext" value="Previous">) 
  	unless $pagenum == 1;

  # check whether it's the last page yet
  if (scalar(@{$self->{xml}[1]} + 1)/4 == $pagenum+1) {
    print qq(<input type="submit" name="wherenext" value="Finish">\n);
  } else {
    print qq(<input type="submit" name="wherenext" value="Next">\n);
  }
  print qq(
    <input type="reset" value="Clear this form">
    </tr>
  );
}

#----------------------------------------------------------------------------
# find_page_by_name($self, $name)
#
# find a page given the NAME attribute.  Returns the numeric index of
# the page, suitable for $wherenext.  That number needs to be multiplied
# by 4 for to get at XML::Parser's representation of it.
#----------------------------------------------------------------------------

sub find_page_by_name {
	my $self = shift;
	my $name = shift;

  # $self->{xml}[1][0] is the attributes of the "form" element.
  # $self->{xml}[1][4] is the first page. 
  # $self->{xml}[1][8] is the second page.
  # $self->{xml}[1][8][4] is the first field of the second page.  
	
	for (my $i = 4; $i < scalar($self->{xml}[1]); $i += 4) { 
		debug($self, "Checking XML bit $i");
		debug($self, "Name is $self->{xml}[1][$i][0]->{NAME}");
		return $i/4 if $self->{xml}->[1][$i][0]->{NAME} eq "$name";
	}
}

#----------------------------------------------------------------------------
# display_fields($self, $cgi)
#
# displays the fields for a page by looping through them
#----------------------------------------------------------------------------

sub display_fields {
  my ($self, $cgi) = @_;

  # $self->{current_page} is a big array. To find info about field N,
  # access element 4*N . 
  
  my @fields;
  for (my $i=4; $i <= scalar @{$self->{current_page}}; $i=$i+4) {
    push (@fields, $self->{current_page}[$i][0] );
  }

  my @definitions;

  # HTML::TagMaker gives us an easy way to make form widgets.
  my $tagmaker = FormMagick::TagMaker->new();

  while (my $fieldinfo = shift @fields  ) {

    my $validation = $fieldinfo->{VALIDATION};
    my $label = $fieldinfo->{LABEL};
    my $type = $fieldinfo->{TYPE};
    my $fieldname = $fieldinfo->{ID};
    my $option_function = $fieldinfo->{OPTIONS};
    my $value = $fieldinfo->{VALUE};
    my $description = $fieldinfo->{DESCRIPTION};

    print_field_description($description) if $description;

    my $inputfield;

    my $valueref;       # a hashref or arrayref returned by an options function
    my @option_values;  # values for an options list
    my @option_labels;  # displayed labels for an options list

    # if this is a grouped input (one with options), we'll need to
    # run the options function for it. 
    if (($type eq "SELECT") || ($type eq "RADIO")) {

      my $options_attribute = $fieldinfo->{'OPTIONS'} || "";
      my $options_ref = $self->parse_options_attribute($cgi, $options_attribute);

      if (ref($options_ref) eq "HASH") {
        foreach my $k (sort keys %$options_ref) {
          push @option_labels, $k;
          push @option_values, $options_ref->{$k};
        }
      } elsif (ref($options_ref) eq "ARRAY") {
        @option_labels = @$options_ref;
        @option_values = @$options_ref;
      } else {
        debug($self, "Something weird's going on.");
      }
    }

    if ($type eq "SELECT") {

      # Make a select box.  Yes, the []s in the option_group() call are a 
      # bit weird, but that's the syntax that works. -srl

      $inputfield = $tagmaker->select_start( 
		type => "$type", 
		name => "$fieldname"
	    ) .  $tagmaker->option_group( 
	    	value => [@option_values], 
		text => [@option_labels]
            ) .  $tagmaker->select_end;
    } elsif ($type eq "RADIO") {
	    $inputfield = $tagmaker->radio_group(type => "$type",
		name => "$fieldname",
		value => [@option_values],
		text => [@option_labels] );
    } else {
	    my %translation_table = (
			     TEXTAREA => 'textarea',
			     CHECKBOX => 'input_field',
			     TEXT => 'input_field',
			     );
            my $function_name = $translation_table{$type};
	    $inputfield = $tagmaker->$function_name(type => "$type",
						    name => "$fieldname",
						    value => "$value",
						    );
    }
	
    print qq(<tr><td class="label">) . localise($label) . qq(</td>
    	<td class="field">$inputfield</td></tr>);

  }

}

#----------------------------------------------------------------------------
# print_page_header($self)
#
# prints the title and description for the top of a page
#----------------------------------------------------------------------------

sub print_page_header {

  my $self = shift;
  # the level 2 heading is the PAGE element's TITLE heading
  print "<h2>", localise($self->{current_page}[0]->{TITLE}), "</h2>\n";

  if ($self->{current_page}[0]->{DESCRIPTION}) {
	  print '<p class="pagedescription">', localise($self->{current_page}[0]->{DESCRIPTION}), "</p>\n";
  }
}

#----------------------------------------------------------------------------
# print_field_description($description)
#
# prints the description of a field
#----------------------------------------------------------------------------

sub print_field_description {
	my $d = shift;
	print qq(<tr><td class="fielddescription" colspan=2>$d</td></tr>);
}

#----------------------------------------------------------------------------
# parse_template($filename)
#
# parses a Text::Template file and returns the result
#----------------------------------------------------------------------------

sub parse_template {
	my $filename = shift;
	carp("Template file $filename does not exist") unless -e $filename;
	my $template = new Text::Template (
		TYPE => 'FILE', 
		SOURCE => $filename
	);
	my $output = $template->fill_in();
	return $output;
}

#----------------------------------------------------------------------------
# localise($string)
#
# Translates a string into the end-user's preferred language by checking
# their HTTP_ACCEPT_LANG variable and pushing it through
# Locale::Maketext
#----------------------------------------------------------------------------

sub localise {
	my $string = shift || "";
	if (my $localised_string = $language->maketext($string)) {
		return $localised_string;
	} else {
		warn "L10N warning: No localisation string found for '$string' for language $ENV{HTTP_ACCEPT_LANGUAGE}";
		return $string;
	}
}

=pod

=head2 add_lexicon()

This method takes two arguments.  The first is a two-letter string
representing the language to which entries should be added.  These are
standard ISO language abbreviations, eg "en" for English, "fr" for
French, "de" for German, etc.  

The second argument is a hashref in which the keys of the hash are the 
phrases to be translated and the values are the translations.

For more information about how localization (L10N) works in FormMagick,
see C<FormMagick::L10N>.

=cut

#----------------------------------------------------------------------------
# add_lexicon($lang, $lexicon_hashref)
#
# adds items to a language lexicon for localisation
#----------------------------------------------------------------------------

sub add_lexicon {
	my $self = shift;
	my ($lang, $lex_ref) = @_;

	# much reference nastiness to point to the Lexicon we want to change
	# ... couldn't have done this without Schuyler's help.  Ergh.

	no strict 'refs';
	my $changeme = "FormMagick::L10N::${lang}::Lexicon";

	my $hard_ref = \%$changeme;

	while (my ($a, $b) = each %$lex_ref) {
		$hard_ref->{$a} = $b;
	}
	use strict 'refs';

	#debug($self, "Our two refs are $hard_ref and $lex_ref");
	#debug($self, "foo is " . localise("foo"));
	#debug($self, "Error is " . localise("Error"));

}

=pod

=head2 debug($msg)

The debug method prints out a nicely formatted debug message.  It's
usually called from your script as C<$f->debug($msg)>

=cut

#----------------------------------------------------------------------------
# debug($msg)
#
# print a debug message.
#----------------------------------------------------------------------------

sub debug {
	my $self = shift;
	my $msg = shift;
	print qq(<p class="debug">$msg</p>) if $self->{debug};
}


#----------------------------------------------------------------------------
# check_l10n()
# print out lexica to check whether they're what you think they are
# this is mostly for debugging purposes
#----------------------------------------------------------------------------

sub check_l10n {
	my $self = shift;
	print qq( <p>Your choice of language: $ENV{HTTP_ACCEPT_LANGUAGE}</p>);
	my @langs = split(/, /, $ENV{HTTP_ACCEPT_LANGUAGE});
	foreach my $lang (@langs) {
		print qq(<h2>Language: $lang</h2>);

		no strict 'refs';
		my $lex= "FormMagick::L10N::${lang}::Lexicon";
		debug($self, "Lexicon name is $lex");
		debug($self, scalar(keys %$lex) . " keys in lexicon");
		foreach my $term (keys %$lex) {
			print qq(<p>$term<br>
				<i>$lex->{$term}</i></p>);
		}			
		use strict 'refs';
	}
}

#----------------------------------------------------------------------------
# validate_input($self, $cgi)
#
# validates end-user input by calling the appropriate subroutine from the
# FM user's script or from Formmagick::Validator
#----------------------------------------------------------------------------

sub validate_input {

  my ($self, $cgi) = @_;
  $self->debug("Starting validation.");

  use FormMagick::Validator;

  my @fields;

  for (my $i=4; $i <= (length($self->{current_page}) ) ; $i=$i+4) {
    push (@fields, $self->{current_page}[$i][0] );
  }

  my %errors;
  
  foreach my $fieldinfo (@fields) {

    my $validation = $fieldinfo->{VALIDATION};
    next unless $validation;

    my $fieldname = $fieldinfo->{ID};
    my $fieldlabel = $fieldinfo->{LABEL} || "";
    my $fielddata = $cgi->param($fieldname);
    
    $self->debug("Working with field $fieldlabel");
    $self->debug("Validation attribute looks like $validation");
    $self->debug("Data looks like $fielddata");

    my @results;

    # XXX argh! this split statement requires that we write validators like 
    # "lengthrange(4, 10), word" like "lengthrange(4,10), word" in order to 
    # work. Eeek. That's not how this should work. But it was even
    # more broken before (I changed a * to a +). 
    # OTOH, I'm not sure it's fixed now. --srl

    my @validation_routines = split( /,\s+/, $validation);

    $self->debug("Going to perform these validation routines: @validation_routines");

    foreach my $v (@validation_routines) {
	
	# XXX i know this could be better, but it works now at least. -srl

	$v =~  /^(\w+)(?:\((.*)\))?$/ ;
        my $validator = $1;
        my $arg = $2;

        my $result;
	if ($arg) {
	    $result = eval "FormMagick::Validator::$validator('$fielddata', $arg)";
       	} else { 
            $result = eval "FormMagick::Validator::$validator('$fielddata')";
	    $self->debug("Eval failed: $@") unless $result;
        }

	$self->debug("Result is $result");
	push (@results, localise($result)) if ($result ne "OK");
    }

    # for multiple errors, put semicolons between the errors before
    # shoving them in a hash to return.    

    if (@results)   {
	my $formatted_result = join("; ", @results) . "." ;
        $errors{$fieldlabel} = $formatted_result if ($formatted_result ne ".");
    } 

  }
  
  return %errors;
}


#-----------------------------------------------------------------------------
# list_error_messages(%errors)
# prints a list of error messages caused by validation failures
#-----------------------------------------------------------------------------

sub list_error_messages {
	my %errors = @_;
	print qq(<div class="error">\n);
	print qq(<h3>Errors</h3>\n);
	print "<ul>";

	foreach my $field (keys %errors) {
		print "<li>$field: $errors{$field}\n";
	}
	print "</ul></div>\n";
}


#-----------------------------------------------------------------------------
# parse_options_attribute($options_field)
#
# parses the OPTIONS attibute from a FIELD element and returns a
# reference to either a hash or an array containing the relevant data to
# fill in a SELECT box or a RADIO group.
#-----------------------------------------------------------------------------

sub parse_options_attribute {
  my $self = shift;
  my $cgi = shift;
  my $options_field = shift;

  # we need a reference to keep the options in, as we don't know if 
  # they'll be a list or a scalar.  When we've got what we want, we
  # can do a ref($options_ref) to find out what flavour we got.

  my $options_ref;

  if ($options_field =~ /=>/) {			# user supplied a hash	
    $options_ref = { eval $options_field };	# make options_ref a hashref
  } elsif ($options_field =~ /,/) {		# user supplied an array
    $options_ref = [ eval $options_field ];	# make options_ref an arrayref
  } else {					# user supplied a sub name
    $options_field =~ s/\(.*\)$//;		# strip parens
    $options_ref = call_options_routine($self, $cgi, $options_field);
  }
  return $options_ref;
}

#-----------------------------------------------------------------------------
# call_options_routine($self, $cgi, $options_field)
# given the options field (eg OPTIONS="myroutine") call that routine
# returns a reference to a hash or array with the options list in it
#-----------------------------------------------------------------------------

sub call_options_routine {
  my $self = shift;
  my $cgi = shift;
  my $options_field = shift;

  # we got here through three layers of call stack, so walk up the stack
  # three times. The 0th element of caller() is the package that's using
  # FormMagick.pm, eg "My::App". 
  my $calling_package = (caller(3))[0] || "";

  # strip leading directory name blah
  #$calling_file =~ s{[^/]+/}{};
  #$calling_file =~ s{.*/}{};

  # This sets up a reference to the sub that'll fill this SELECT
  # box with data. We need to pass this CGI object to it, in case
  # for some reason the function wants to use a submitted value
  # from the CGI in a database query that populates the SELECT.
  # It ends up looking something like \&main::get_select_options(\$cgi).
  # --srl
  my $voodoo = "\&$calling_package\:\:$options_field(\$cgi)"; 

  my $options_ref;

  unless ($options_ref = eval $voodoo) {
    # it seems like the right thing to do if there is no value list
    # returned is to barf out a warning and leave the list blank.
    debug ($self, "Couldn't obtain a value list from $voodoo for field");
    my $options_ref = "";
  }
  return $options_ref;
}

#-----------------------------------------------------------------------------
# calling_info()
# find out what file called FormMagick, so we can refer to 
# routines defined there.
#-----------------------------------------------------------------------------

sub calling_info {
    my $calling_file = (caller(2))[1];
    $calling_file =~ s!.*/!!;	# strip leading directories

    return $calling_file;
}


sub form_pre_event {
   my ($self, $cgi) = @_;

   # this is the routine where we call some routine that will
   # give us default data for the form, or otherwise
   # do things that need doing before the form is submitted.

    # find out what the form pre_event action is. 
    my $pre_form_routine = $self->{xml}[1][0]->{'PRE-EVENT'};

    my $calling_file = calling_info();

    my $voodoo = "\&$calling_file\:\:$pre_form_routine(\$cgi)"; 

    # if the pre_form_routine is defined in the calling file, 
    # it'll run. Otherwise, we'll give some simple display of the
    # variables that were submitted.

    unless (eval $voodoo) {
	debug($self, "<p>There was no pre-form routine.</p>\n")
    }

}

sub form_post_event {
    my ($self, $cgi) = @_;
    
    # XXX we need to validate EVERY ONE of the form inputs to make
    # sure malicious attacks don't happen. 

    # IOW, walk the XML parse tree, find each field, grab its data, and
    # validate it, again. But what do we do when something doesn't validate?
    # Drop the user back to that page, or just display a field for them to 
    # correct it?

    # print "<p>The following is unvalidated data. Process at your own risk.";
    
    # find out what the form post_event action is. 
    my $post_form_routine = $self->{xml}[1][0]->{'POST-EVENT'};

    unless (do_external_routine($self, $cgi, $post_form_routine)) {

	print "The following data was submitted:\n";
	print "<ul>\n";
        my @params = $cgi->param;
	foreach my $param (@params) {
	    my $value =  $cgi->param($param);
	    print "<li>$param: $value\n";
	}
	print "</ul>\n";
    }

    exit;
}

sub page_pre_event {
    my ($self, $cgi) = @_;
    debug($self, "This is the page pre-event.");
    my $pre_page_routine = $self->{current_page}[0]->{'PRE-EVENT'};
    do_external_routine($self, $cgi, $pre_page_routine);
}

sub page_post_event {
    my ($self, $cgi) = @_;
    debug($self, "This is the page post-event.");
    my $post_page_routine = $self->{current_page}[0]->{'POST-EVENT'};
    do_external_routine($self, $cgi, $post_page_routine);
}

sub do_external_routine {
	my $self = shift;	
	my $cgi = shift;	
	my $routine = shift || "";

	my $calling_package = (caller(2))[0];
	#debug($self, "Calling package is $calling_package");

	my $voodoo = "\&$calling_package\:\:$routine(\$cgi)"; 

	debug($self, "Voodoo is $voodoo");

	if (eval $voodoo) {
		return 1;
	} else {
		debug($self, "There was no routine defined.");
		return 0;
	}
}


=pod 


=head2 Form descriptions

Sample form description

The following is an example of how a form is described in XML. More
complete examples can be found in the C<examples/> subdirectory in the
FormMagick distribution.

  <FORM TITLE="My form application" HEADER="myform_header.tmpl" 
    FOOTER="myform_footer.tmpl" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" DESCRIPTION="Please
    provide us with the following personal details for our records">
      <FIELD ID="firstname" LABEL="Your first name" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="Your surname" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="username" LABEL="Choose a username" TYPE="TEXT" 
        VALIDATION="username" DESCRIPTION="Your username must
	be between 3 and 8 characters in length and contain only letters
	and numbers."/>
    </PAGE>
    <PAGE NAME="Payment" TITLE="Payment details"
    POST-EVENT="check_credit_card" DESCRIPTION="We need your full credit
    card details to process your order.  Please fill in all fields.
    Your card will be charged within 48 hours.">
      <FIELD ID="cardtype" LABEL="Credit card type" TYPE="SELECT" 
        OPTIONS="list_credit_card_types" VALIDATION="credit_card_type"/>
      <FIELD ID="cardnumber" LABEL="Credit card number" TYPE="TEXT" 
        VALIDATION="credit_card_number"/>
      <FIELD ID="cardexpiry" LABEL="Expiry date (MM/YY)" TYPE="TEXT" 
        VALIDATION="credit_card_expiry"/>
    </PAGE>
  </FORM>

The XML must comply with the FormMagick DTD (included in the
distribution as FormMagick.dtd).  A command-line tool to test compliance
is planned for a future release.

=head1 SEE ALSO

FormMagick::L10N

FormMagick::Validator

FormMagick::FAQ

=head1 BUGS

There are a number of features which have not yet been implemented.
Also, there are probably mismatches between this perldoc and the actual
functionality.

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

Contributors:

Shane R. Landrum <slandrum@turing.csc.smith.edu>

James Ramirez <jamesr@cogs.susx.ac.uk>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

