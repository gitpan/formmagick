#!/usr/bin/perl -wT

#----------------------------------------------------------------------
# heading     : Configuration
# description : Email retrieval
# navigation  : 2000 2700
# 
# copyright (C) 1999-2001 e-smith, inc.
# 		
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 		
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 		
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
# 
# Technical support for this program is available from e-smith, inc.
# For details, please visit our web site at www.e-smith.com or
# call us on 1 888 ESMITH 1 (US/Canada toll free) or +1 613 564 8000
#----------------------------------------------------------------------

package esmith;

use strict;
use CGI ':all';
use CGI::Carp qw(fatalsToBrowser);

use esmith::cgi;
use esmith::config;
use esmith::util;
use esmith::db;

sub showInitial ($);
sub performAndShowResult ($);

BEGIN
{
    # Clear PATH and related environment variables so that calls to
    # external programs do not cause results to be tainted. See
    # "perlsec" manual page for details.

    $ENV {'PATH'} = '';
    $ENV {'SHELL'} = '/bin/bash';
    delete $ENV {'ENV'};
}

esmith::util::setRealToEffective ();

$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

my %conf;
tie %conf, 'esmith::config';


#------------------------------------------------------------
# examine state parameter and display the appropriate form
#------------------------------------------------------------

my $q = new CGI;

if (! grep (/^state$/, $q->param))
{
    showInitial ($q);
}

elsif ($q->param ('state') eq "perform")
{
    performAndShowResult ($q);
}

else
{
    esmith::cgi::genStateError ($q, \%conf);
}

exit (0);

#------------------------------------------------------------
# subroutine to display initial form
#------------------------------------------------------------

sub showInitial ($)
{
    my ($q) = @_;

    my $FetchmailFreqOffice = db_get_prop(\%conf, "fetchmail", "FreqOffice")
	|| 'every15min';
    my $FetchmailFreqOutside = db_get_prop(\%conf, "fetchmail", "FreqOutside")
	|| 'everyhour';
    my $FetchmailFreqWeekend = db_get_prop(\%conf, "fetchmail", "FreqWeekend")
	|| 'everyhour';
    my $FetchMethod =
	(db_get_prop(\%conf, "fetchmail", "status") eq 'enabled') ?
	(db_get_prop(\%conf, "fetchmail", "Method") || 'standard') :
	'standard';
    my $DelegateMailServer = db_get(\%conf, "DelegateMailServer")
	|| '';
    my $SecondaryMailServer =
	db_get_prop(\%conf, "fetchmail", "SecondaryMailServer")
	|| '';
    my $SecondaryMailAccount =
	db_get_prop(\%conf, "fetchmail", "SecondaryMailAccount")
	|| '';
    my $SecondaryMailPassword =
	db_get_prop(\%conf, "fetchmail", "SecondaryMailPassword")
	|| '';
    my $SecondaryMailEnvelope =
	db_get_prop(\%conf, "fetchmail", "SecondaryMailEnvelope");

    my $SecondaryMailUseEnvelope;
    if (defined $SecondaryMailEnvelope)
    {
	$SecondaryMailUseEnvelope = "on";
    }
    else
    {
	$SecondaryMailUseEnvelope = "off";
	$SecondaryMailEnvelope = "";
    }

    esmith::cgi::genHeaderNonCacheable ($q,
	\%conf, 'Change email retrieval settings');

    print $q->startform (-method => 'POST',
			-action => $q->url (-absolute => 1));

    my %labels0 = ('standard'  => 'Standard',
		   'etrn'      => 'ETRN',
		   'multidrop' => 'Multi-drop');

    my %labels1 = ('off' => 'Default',
		   'on'  => 'Specify below');

    my @keys2 = (
	'never',
	'every5min',
	'every15min',
	'every30min',
	'everyhour',
	'every2hrs'
	);

    my %labels2 = ('never'      => 'Not at all',
                   'every5min'  => 'Every 5 minutes',
                   'every15min' => 'Every 15 minutes',
                   'every30min' => 'Every 30 minutes',
                   'everyhour'  => 'Every hour',
                   'every2hrs'  => 'Every 2 hours');

    print $q->table ({border => 0, cellspacing => 0, cellpadding => 4},

        esmith::cgi::genTextRow ($q,
	    $q->p ('The mail retrieval mode can be set to standard',
	    '(for dedicated Internet connections), ETRN (recommended for',
	    'dialup connections), or multi-drop (for dialup connections',
	    'if ETRN is not supported by your Internet provider).')),

        esmith::cgi::genWidgetRow ($q, "Email retrieval mode",
	       $q->popup_menu (-name => 'mode',
			       -values => ['standard', 'etrn', 'multidrop'],
			       -default => $FetchMethod,
			       -labels => \%labels0)),

        esmith::cgi::genTextRow ($q,
	    $q->p ('Your e-smith system includes a complete, full-featured',
	    'email server. However, if for some reason you wish',
	    'to delegate email processing to another system, specify',
	    'the IP address of the delegate system here.',
	    'For normal operation, leave this field blank.')),

        esmith::cgi::genNameValueRow ($q,
				      "Delegate mail server",
				      "delegate",
				      $DelegateMailServer),

        esmith::cgi::genTextRow ($q,
	    $q->p ('For ETRN or multi-drop, specify the hostname or IP',
	    'address of your secondary mail server. (If using the',
	    'standard email setup, this field can be left blank.)')),

        esmith::cgi::genNameValueRow ($q,
				      "Secondary mail server",
				      "server",
				      $SecondaryMailServer),

        esmith::cgi::genTextRow ($q,
	    $q->p ('For ETRN or multi-drop, you can control how frequently',
	    'the e-smith server and gateway contacts your secondary',
	    'email server to fetch email. More frequent connections',
	    'mean that you receive your email more quickly, but also',
	    'cause Internet requests to be sent more often, possibly',
	    'increasing your phone and Internet charges.')),

        esmith::cgi::genWidgetRow ($q,
	   "During office hours (8:00 AM to 6:00 PM) on weekdays",
		   $q->popup_menu (-name => 'fetchmailFreqOffice',
				   -values => \@keys2,
				   -default => $FetchmailFreqOffice,
				   -labels => \%labels2)),

        esmith::cgi::genWidgetRow ($q,
	   "Outside office hours (8:00 AM to 6:00 PM) on weekdays",
		   $q->popup_menu (-name => 'fetchmailFreqOutside',
				   -values => \@keys2,
				   -default => $FetchmailFreqOutside,
				   -labels => \%labels2)),

        esmith::cgi::genWidgetRow ($q,
	   "During the weekend",
		   $q->popup_menu (-name => 'fetchmailFreqWeekend',
				   -values => \@keys2,
				   -default => $FetchmailFreqWeekend,
				   -labels => \%labels2)),

        esmith::cgi::genTextRow ($q,
	    $q->p ('For multi-drop email, specify the POP user account',
	    'and password. (If using standard or ETRN email, these',
	    'fields can be blank.) Also, for multi-drop, you can either',
	    'use the default e-smith server and gateway mail sorting',
	    'method, or you can specify a particular message header',
	    'to use for mail sorting.')),

        esmith::cgi::genNameValueRow ($q,
		  "POP user account (for multi-drop)", "account",
				      $SecondaryMailAccount),

        esmith::cgi::genNameValueRow ($q,
		  "POP user password (for multi-drop)", "password",
				      $SecondaryMailPassword),

        esmith::cgi::genWidgetRow ($q,
		   "Select sort method (for multi-drop)",
			       $q->popup_menu (-name => 'specifyHeader',
				   -values => ['off', 'on'],
				   -default => $SecondaryMailUseEnvelope,
				   -labels => \%labels1)),

        esmith::cgi::genNameValueRow ($q,
		  "Select sort header (for multi-drop)", "header",
				      $SecondaryMailEnvelope),

        esmith::cgi::genButtonRow ($q,
		       $q->submit (-name => 'action', -value => 'Save')));

    print $q->hidden (-name => 'state', -override => 1, -default => 'perform');
    print $q->endform;
    esmith::cgi::genFooter ($q);
}

#------------------------------------------------------------
# subroutine to perform actions and display result
#------------------------------------------------------------

sub performAndShowResult ($)
{
    my ($q) = @_;

    #------------------------------------------------------------
    # Verify the arguments and untaint the variables (see Camel
    # book, "Detecting and laundering tainted data", pg. 358)
    #------------------------------------------------------------

    my $mode = $q->param ('mode');
    if ($mode =~ /^(.*)$/)
    {
	$mode = $1;
    }
    else
    {
	$mode = "standard";
    }

    my $delegate = $q->param ('delegate');
    if ($delegate =~ /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/)
    {
	$delegate = $1;
    }
    elsif ($delegate =~ /^\s*$/)
    {
	$delegate = "";
    }
    else
    {
        esmith::cgi::genHeaderNonCacheable ($q, \%conf,
	    "Error while changing email retrieval settings");
        esmith::cgi::genResult ($q,
	    "Invalid delegate email server \"$delegate\". " .
	    "Please make sure you specify a numeric IP address.");
	return;
    }
    
    my $server = $q->param ('server');
    if ($server =~ /^(.*)$/)
    {
	$server = $1;
    }
    else
    {
	$server = "";
    }
    
    my $fetchmailFreqOffice = $q->param ('fetchmailFreqOffice');
    if ($fetchmailFreqOffice =~ /^(.*)$/)
    {
        $fetchmailFreqOffice = $1;
    }
    else
    {
        $fetchmailFreqOffice = "every15min";
    }

    my $fetchmailFreqOutside = $q->param ('fetchmailFreqOutside');
    if ($fetchmailFreqOutside =~ /^(.*)$/)
    {
        $fetchmailFreqOutside = $1;
    }
    else
    {
        $fetchmailFreqOutside = "everyhour";
    }

    my $fetchmailFreqWeekend = $q->param ('fetchmailFreqWeekend');
    if ($fetchmailFreqWeekend =~ /^(.*)$/)
    {
        $fetchmailFreqWeekend = $1;
    }
    else
    {
        $fetchmailFreqWeekend = "everyhour";
    }

    my $account = $q->param ('account');
    if ($account =~ /^(.*)$/)
    {
	$account = $1;
    }
    else
    {
	$account = "";
    }
    
    my $password = $q->param ('password');
    if ($password =~ /^(.*)$/)
    {
	$password = $1;
    }
    else
    {
	$password = "";
    }
    
    my $specifyHeader = $q->param ('specifyHeader');
    if ($specifyHeader =~ /^(.*)$/)
    {
	$specifyHeader = $1;
    }
    else
    {
	$specifyHeader = "off";
    }

    my $header = $q->param ('header');
    if ($header =~ /^(.*)$/)
    {
	$header = $1;
    }
    else
    {
	$header = "";
    }

    #------------------------------------------------------------
    # Looks good; go ahead and save the settings.
    #------------------------------------------------------------

    my $old = db_get(\%conf, 'UnsavedChanges');

    if ($delegate eq "")
    {
	db_delete(\%conf, 'DelegateMailServer');
    }
    else
    {
	db_set(\%conf, 'DelegateMailServer', $delegate);
    }

    db_set(\%conf, "fetchmail", "service", { status => "disabled"})
	unless (db_get(\%conf, "fetchmail"));

    if ($mode eq 'standard')
    {
	db_set_prop(\%conf, "fetchmail", 'status', 'disabled');
	db_set_prop(\%conf, "fetchmail", 'Method', 'standard');
    }
    else
    {
	db_set_prop(\%conf, "fetchmail", 'status', 'enabled');
	db_set_prop(\%conf, "fetchmail", 'Method', $mode);
	db_set_prop(\%conf, "fetchmail", 'SecondaryMailServer', $server)
	    unless ($server eq '');;
	db_set_prop(\%conf, "fetchmail", 'FreqOffice', $fetchmailFreqOffice);
	db_set_prop(\%conf, "fetchmail", 'FreqOutside', $fetchmailFreqOutside);
	db_set_prop(\%conf, "fetchmail", 'FreqWeekend', $fetchmailFreqWeekend);
	db_set_prop(\%conf, "fetchmail", 'SecondaryMailAccount', $account)
	    unless ($account eq '');
	db_set_prop(\%conf, "fetchmail", 'SecondaryMailPassword', $password)
	    unless ($password eq '');
	if ($specifyHeader eq 'on')
	{
	    db_set_prop(\%conf, "fetchmail", 'SecondaryMailEnvelope', $header);
	}
	else
	{
	    db_delete_prop(\%conf, "fetchmail", 'SecondaryMailEnvelope');
	}
    }
    db_set(\%conf, 'UnsavedChanges', $old);

    system ("/sbin/e-smith/signal-event", "email-update") == 0
	or die ("Error occurred while updating system configuration.\n");

    esmith::cgi::genHeaderNonCacheable ($q,
	\%conf, "Email retrieval settings saved successfully");
    esmith::cgi::genResult ($q,
	"The new email retrieval settings have been saved.");
    return;
}
