#!/usr/bin/perl -w

#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.
#
# $Id: Validator.pm,v 1.15 2001/02/23 20:55:09 skud Exp $
#

package    FormMagick::Validator;
require    Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw( nonblank number word url username maxlength minlength exactlength);

=pod
=head1 NAME

FormMagick::Validator - validate data from FormMagick forms

=head1 SYNOPSIS

use FormMagick::Validator;

=head1 DESCRIPTION

This module provides some common validation routines.  Validation
routines return the string "OK" if they succeed, or a descriptive
message if they fail.

=head2 Validation routines provided:

=over 4

=item nonblank

The data is not an empty string : C<$data ne "">

=cut 

sub nonblank {
	my $data = $_[0];
	if ($data ne "") {
		return "OK";
	} else {
		return "This field must not be left blank"; 
	}
}

=pod

=item number

The data is a number (strictly speaking, data is a positive number):
C<$data =~ /^[0-9.]+$/>

=cut

sub number {
	my $data = $_[0];
	if ($data =~ /^[0-9.]+$/) {
		return "OK";
	} else {
		return "This field must contain a positive number";
	}
}

=pod

=item word

The data looks like a single word: C<$data !~ /\W/>

=cut

sub word {
	my $data = $_[0];
	if ($data =~ /^\w/) {
		return "OK";
	} else {
		return "This field must look like a single word.";
	}

}

=pod

=item minlength(n)

The data is at least C<n> characters long: C<length($data) E<gt>= $n>

=cut

sub minlength {
	my $data = $_[0];
	my $minlength= $_[1];
	if ( length($data) >= $minlength ) {
		return "OK";
	} else {
		return "This field must be at least $minlength characters";
	}
}


=pod

=item maxlength(n)

The data is no more than  C<n> characters long: C<length($data) E<lt>= $n>

=cut

sub maxlength {
	my $data = $_[0];
	my $maxlength= $_[1];
	if ( length($data) <= $maxlength ) {
		return "OK";
	} else {
		return "This field must be no more than $maxlength characters";
	}
}

=pod

=item exactlength(n)

The data is exactly  C<n> characters long: C<length($data) E== $n>

=cut

sub exactlength {
	my $data = $_[0];
	my $exactlength= $_[1];
	if ( length($data) == $exactlength ) {
		return "OK";
	} else {
		return "This field must be exactly $exactlength characters";
	}
}


=pod

=item lengthrange(n,m)

The data is between  C<n> and c<m> characters long: C<length($data) E<gt>= $n>
and C<length($data) E<lt>= $m>.
=cut

sub lengthrange {
	my $data = $_[0];
	my $minlength= $_[1];
	my $maxlength= $_[2];
	print "min $minlength, max $maxlength";
	if ( ( length($data) >= $minlength ) and (length($data) <= $maxlength) ) {
	        return "OK";
	} else {
		return "This field must be between $minlength and $maxlength characters";
	}
}


=pod


=item url

The data looks like a (normalish) URL: C<$data =~ m!(http|ftp)://[\w/.-/)!>

=cut

sub url {
	my $data = $_[0];
	if ($data =~ m!(http|ftp)://[\w/.-/]!) {
		return "OK";
	} else {
		return "This field must contain a URL starting with http:// or ftp://";
	}
}

=pod

=item email 

The data looks more or less like an internet email address:
C<$data =~ /\@/> 

Note: not fully compliant with the entire gamut of RFC 822 addressing ;)

=cut

sub email {
	my $data = $_[0];
	if ($data =~ /\@/) {
		return "OK";
	} else {
		return "This field doesn't look like an email address - it should contain an at-sign (\@)";
	}
}

=pod

=item domain_name

The data looks like an internet domain name or hostname.

=cut

sub domain_name {
	my $data = shift;
	if ($data =~ /^([a-z\d\-]+\.)+[a-z]{1,3}$/o ) {
		return "OK";
	} else {
		return "This field doesn't look like a valid Internet domain name or hostname.";
	}
}

=pod

=item ip_number

The data looks like a valid IP number.

=cut

sub ip_number {
	my $data = $_[0];

	require Net::IPV4Addr;

	if (ipv4_chkip($data)) {
		return OK;
	} else {
		return "This field doesn't look like an IP number.";
	}

}

=pod
    
=item username

The data looks like a good, valid username

=cut

sub username {
	my $data = $_[0];

	if ($data =~ /[a-zA-Z]{3,8}/ ) {
		return "OK";
	} else {
		return "This field must look like a valid username (3 to 8 letters and numbers)";
	}
}

=pod

=item password

The data looks like a good password

=cut

sub password {
	my $data = $_[0];
	return "XXX NOT YET IMPLEMENTED";
}

=pod

=item date

The data looks like a date.

=cut

sub date {
	my $data = $_[0];
	use Time::ParseDate;
	if (my $time = parsedate($data)) {
		return "OK";
	} else {
		return "The data entered could not be parsed as a date"
	}
}

=pod

=item iso_country_code

The data is a standard 2-letter ISO country code.  Uses Locale::Country to
check.

=cut

sub iso_country_code {
	my $data = $_[0];

	use Locale::Country;
	my @countries =  all_country_codes();

	foreach $country (@countries) {
	    if ($data eq $country) {
		return "OK";
	    }
	}
	return "This field does not contain an ISO country code";
}

=pod

=item US_state

The data is a standard 2-letter US state abbreviation.  Uses
Geography::State in non-strict mode.

=cut

sub US_state {
	my $data = $_[0];
	use Geography::States;

	my $us = Geography::States->new('USA');

	if ($us->state(uc($data))) {
		return "OK";
	} else {
		return "This doesn't appear to be a valid 2-letter US state abbreviation"
	}			
}

=pod

=item US_zipcode

The data looks like a valid US zipcode

=cut

sub US_zipcode {
	my $data = $_[0];

	# pedantic point: US ZIP codes must contain 5 numbers, can
	# contain 9 (like "30308-1112"). Someone want to fix this?
 
	if ($data =~ /^\d{5}$/) {
		return "OK";
	    } else {
		return "US zip codes must contain 5 numbers";
	}
}

=pod

=item credit_card_type

The data looks like a valid type of credit card (eg Visa, Mastercard).
Uses Business::CreditCard.

=cut

sub credit_card_type {
	my $data = $_[0];
        use Business::CreditCard;
	return "XXX NOT YET IMPLEMENTED";
}

=pod

=item credit_card_number

The data looks like a valid credit card number
Uses Business::CreditCard.

=cut

sub credit_card_number {
	my $data = $_[0];
	use Business::CreditCard;

	return "XXX NOT YET IMPLEMENTED";
}

=pod

=item credit_card_expiry

The data looks like a valid credit card expiry date
Uses Business::CreditCard.

=cut

sub credit_card_expiry {
	my $data = $_[0];
	use Business::CreditCard;

	return "XXX NOT YET IMPLEMENTED";
}



=pod

=back

These validation routines may be overridden and others may be added on 
a per-application basis.  To do this, simply define a subroutine in your
CGI script that works in a similar way and use its name in the
VALIDATION attribute in your XML.

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
