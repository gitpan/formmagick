#!/usr/local/bin/perl -wT

# $Log: testsuite.pl,v $
# Revision 1.1  2001/02/22 20:37:04  srl
# Cleaned up the make process some:
#
# - updated the MANIFEST so it doesn't give errors. It needs to have
# the e-smith testing files added to it if we're going to put those in
# the distribution.
#
# - removed HTML::FormMaker as a requirement from Makefile.PL until
# we get that mess cleaned up (yes, it's on my TODO.)
#
# - moved the tests around so that they're in a proper test/ directory,
# as a preface to getting testing working as it should.
#
# As of this commit, I can type "perl Makefile.PL; make; make test" and
# everything works here. Haven't tried "make install" yet.
#
# Revision 1.2  2000/12/11 23:28:12  skud
# Again, more updates for 0.2.0.
# In particular, I've been through FormMagick.pm and done a bit of minor
# code cleanup (mostly just idiom fixes; srl, check the diffs) and also
# marked areas that need work with "XXX".
#
# Revision 1.1  2000/12/09 05:52:28  srl
# At last, some unit tests so we don't have to use a browser to test
# the validation routines. This is just a start; I'd appreciate it if
# someone could take a look and see if these seem sane. I tried to
# grab boundary cases whenever I could.
#

# This is a unit-testing module for FormMagick. The idea is
# to test *every* function we use to make sure it works.
# This is primarily a developer's tool, so that when you've
# modified something you don't have to actually click
# "Reload" to make sure it works. 

# We need two kinds of tests: one to test the routines
# themselves (like validation, for example) and the other
# to walk a form and actually show that it works like it's
# supposed to. 

# I really don't like how the failed tests give pages and
# pages of tracebacks.  Perhaps someone can fix this?


use lib ".";
use strict;
use Test::Unit;
use FormMagick::Validator; 

# replace this with your preferred URL pointing to the testfm.pl script
# running behind a webserver. 

my $url_to_test = "http://127.0.0.1/srl/perl/formmagick/testfm.pl";


sub test_nonblank_simple_reject {
    # give an error on a blank field.
    assert (nonblank("") ne "OK");
}

sub test_nonblank_simple_accept {    
    # don't give an error on a nonblank field.
    assert (nonblank("foobar") eq "OK");
}

sub test_number_simple_reject {
    # give an error on a non-numeric entry.
    assert (number("ABC") eq "OK");
}

sub test_number_simple_accept {
    # don't error on a number. 
    assert (number("2") eq "OK");
}

sub test_number_0_accept {
    # border case: is 0 a number? (Should be yes) 
    assert (number("0") eq "OK");
}

sub test_number_000_accept {
    # border case: is 000 a number? (Should be yes, I think) 
    assert (number("000") eq "OK");
}

sub test_number_blank_reject {
    # border case: is "" a number? (Should be no, I think) 
    assert (number("") ne "OK");
}


sub test_word_simple_accept {
    # Accept a string of all letters. 
    assert (word("thistest") eq "OK");
}

sub test_word_simple_reject {
    # Reject a string containing numbers.
    assert (word("abc123xyz") ne "OK");
}

sub test_word_punctuation_reject {
    # Reject a string containing punctuation.
    assert (word("joe!s") ne "OK");
}

sub test_word_realword_accept {
    # Semantics: do we want to test for "is this a real word in my language?"
    # I don't think so. 
    return 1;
}

sub test_minlength_simple_reject {
    # a string is shorter than a specified minimum length.
    assert (minlength('this', 10) ne "OK");
}

sub test_minlength_simple_accept {
    # a string is longer than a specified minimum length.
    assert (minlength('this', 2) ne "OK");
}

sub test_minlength_exact_accept {
    # accept if a string is exactly a specified minimum length.
    assert (minlength('this', 4) eq "OK");
}

sub test_minlength_0_accept {
    # a string is longer than 0.
    assert (minlength('this', 0) eq "OK");
}

sub test_maxlength_simple_reject {
    # reject a string longer than a max length.
    assert (maxlength('this', 3) ne "OK");
}

sub test_maxlength_simple_accept {
    # accept a string shorter than a max length.
    assert (maxlength('this', 10) eq "OK");
}

sub test_maxlength_exact_accept {
    # accept a string exactly the maximum length.
    assert (maxlength('this', 4) eq "OK");
}

sub test_exactlength_simple_accept {
    assert (exactlength('this', 4) eq "OK");
}

sub test_exactlength_lessthan_reject {
    assert (exactlength('the', 4) ne "OK");
}

sub test_exactlength_morethan_reject {
    assert (exactlength('those', 4) ne "OK");
}

sub test_lengthrange_simple_accept {
    # accept something that's clearly within a range
    assert (lengthrange('those', 4, 6) eq "OK");    
}

sub test_lengthrange_low_accept {
    # accept something that's on the lower acceptance of a range
    assert (lengthrange('this', 4, 6) eq "OK");    
}

sub test_lengthrange_high_accept {
    # accept something that's on the high acceptance end of a range
    assert (lengthrange('foobar', 4, 6) eq "OK");    
}

sub test_lengthrange_low_reject {
    # reject something that's on the lower reject end of a range
    assert (lengthrange('the', 4, 6) ne "OK");    
}

sub test_lengthrange_high_reject {
    # reject something that's on the high reject end of a range
    assert (lengthrange('monitor', 4, 6) ne "OK");    
}

sub test_url_simple_accept_http {
    assert (url('http://www.infotrope.net') eq "OK");    
}

sub test_url_simple_accept_ftp {
    assert (url('ftp://ftp.cpan.org') eq "OK");    
}

sub test_url_simple_reject {
    assert (url('memepool.com') ne "OK");    
}

sub test_email_simple_accept {
    assert (email('foo@bar.com') eq "OK");    
}

sub test_email_simple_reject {
    assert (email('bar.com') ne "OK");    
}

sub test_email_complex_accept {
    assert (email('foo@bar.baz.com') eq "OK");    
}

sub test_email_complex_reject {
    assert (email('foo@bar') ne "OK");    
}

sub test_domain_name_simple_accept {
    assert (domain_name('zeroknowledge.com') eq "OK");    
}

sub test_domain_name_simple_reject {
    assert (domain_name('zeroknowledge') ne "OK");    
}

sub test_domain_name_nonus_accept {
    assert (domain_name('netizen.com.au') eq "OK");    
}

sub test_domain_name_threepart_accept {
    assert (domain_name('athena.mit.edu') eq "OK");    
}

sub test_ip_number_simple_accept {
    assert (ip_number('199.245.105.172') eq "OK");    
}

sub test_ip_number_simple_reject {
    # This might actually be legal. Anyone know?
    assert (ip_number('ab.ab.ab.ab') ne "OK");    
}

# The username tests below need a few more boundary cases. 

sub test_username_accept {
    assert (username('user') eq "OK");    
}

sub test_username_numonly_reject {
    assert (username('31337') ne "OK");    
}

sub test_username_oddchars_reject {
    assert (username('Sn|p|ng') ne "OK");    
}

sub test_password_accept {
    assert (password('fokesm23') eq "OK"); 
}

sub test_password_reject {
    # the password function should reject this as too easy. 
    assert (password('foobar') ne "OK"); 
}

# This could use tests for some more exotic date formats. 

sub test_date_USAformat_accept {
    assert (date('Jan 01 2000') eq "OK"); 
}

sub test_date_EUformat_accept {
    assert (date('01 Jan 2000') eq "OK"); 
}

sub test_date_reject {
    assert (date('foobar') ne "OK"); 
}


sub test_iso_country_code_accept {
    assert (iso_country_code('de') eq "OK"); 
}

sub test_iso_country_code_reject {
    assert (iso_country_code('xy') ne "OK"); 
}

sub test_US_state_accept {
    assert (US_state('KY') eq "OK"); 
}

sub test_US_state_reject {
    assert (US_state('ZX') ne "OK"); 
}

# aren't there legal 11-digit ZIP codes? ISTR there are. 

sub test_US_zipcode_5digit_accept {
    assert (US_zipcode('02139') eq "OK"); 
}

sub test_US_zipcode_9digit_accept {
    assert (US_zipcode('02139-4218') eq "OK"); 
}

sub test_US_zipcode_canadian_reject {
    assert (US_zipcode('V3J 1N3') ne "OK"); 
}

sub test_credit_card_type_mc_accept {
    assert (credit_card_type('Mastercard') eq "OK"); 
}

sub test_credit_card_type_visa_accept {
    assert (credit_card_type('VISA') eq "OK"); 
}

sub test_credit_card_type_discover_accept {
    assert (credit_card_type('Discover') eq "OK"); 
}

sub test_credit_card_type_amex_accept {
    assert (credit_card_type('American Express') eq "OK"); 
}

sub test_credit_card_type_reject {
    assert (credit_card_type('bogocard') ne "OK"); 
}

# Can someone write a test for this? I don't know if
# legit card numbers depend on what kind of card it is. 

sub test_credit_card_number_accept {
    return 1;
}

sub test_credit_card_number_reject {
    return 1;
}

sub test_credit_card_expiry_accept {
    assert (credit_card_expiry('01/03') eq "OK"); 
}

sub test_credit_card_expiry_reject {
    assert (credit_card_expiry('2000') eq "OK"); 
}



# Sample tests for FormMagick.pm ----------------------------------
# fill these in someday, maybe.

sub test_new {
    return 1;
}

sub test_display {
    return 1;

}

sub test_display_fields {
    return 1;
}

sub test_parse_template {
    return 1;
}

sub test_localise {
    return 1;
}

sub test_validate_input {
    return 1;
}

sub test_list_error_messages {
    return 1;
}

sub test_calling_info {
    return 1;
}

sub test_form_pre_event {
    return 1;
}

sub test_form_post_event {
    return 1;
}

sub test_page_pre_event {
    return 1;
}

sub test_page_post_event {
    return 1;
}


# This is just a sample. We can use this in the future to test whole pages
# at a time if we want. 

sub test_page_1 {
    # Create a user agent object
    use LWP::UserAgent;
    my $ua = new LWP::UserAgent;

    $ua->agent("AgentName/0.1 " . $ua->agent);
    
    # Create a request
    my $req = new HTTP::Request( POST => "$url_to_test");

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    
    my $id_value;
    
    # Check the outcome of the response
    if ($res->is_success) {
	# get the .id field we'll need to pass through
	foreach my $line ($res->content) {
	    if ( $line =~ /(\.id)" value="([^"]+)"/  ) {
		#print " $1 $2 ";
		$id_value = $2;
	    }
	}

	# make a request with submitted data from page 1. 
	$req->content_type("application/x-www-form-urlencoded");
	$req->content("page=1&firstname=foo&lastname=bar&username=a&.id=$id_value&wherenext=Next");
    
        my $res = $ua->request($req);
	
        # print the data from the submitted page 1, which'll either be
	#	 errors or a new page 2. 

	#foreach my $line ($res->content) {
	#    print $line;
	#}
		 return 1;
    } else {
	die "We couldn't see page 1 for some reason.\n";
	return 0;
    }

}


sub set_up {

}

sub tear_down {
    # this gets run after the tests.
}


# run the tests.
create_suite();
run_suite();









