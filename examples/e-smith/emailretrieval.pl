#!/usr/local/bin/perl -w

use strict;
use FormMagick;

my $fm = new FormMagick(
	#DEBUG => 1,
);

$fm->add_lexicon( "fr", lexicon_fr() );
$fm->display();

# list of mailcheck frequencies

sub mailcheck_frequencies {
	#return {
		#never 		=> "Not at all",
		#every5min 	=> "Every 5 minutes",
		#every15min 	=> "Every 15 minutes",
		#every30min 	=> "Every 30 minutes",
		#everyhour 	=> "Every hour",
		#every2hrs 	=> "Every 2 hours"
	#};
	return [
		"Not at all",
		"Every 5 minutes",
		"Every 15 minutes",
		"Every 30 minutes",
		"Every hour",
		"Every 2 hours"
	];
}

sub post_Retrieval_page {
	my $cgi = shift;
	if ($cgi->param("retrieval_mode") eq "Standard") {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	} else {
		# go to ETRNMultiDropOptions page
		$cgi->param(-name => "wherenext", -value => "ETRNMultiDropOptions");
	}
	return 1;
}

sub post_ETRNMultiDropOptions_page {
	my $cgi = shift;
	if ($cgi->param("retrieval_mode") eq "Multi-drop") {
		# go to MultiDropOptions page
		$cgi->param(-name => "wherenext", -value => "MultiDropOptions");
	} else {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	}
	return 1;
}

sub post_MultiDropOptions_page {
	my $cgi = shift;
	if ($cgi->param("sort_method") eq "Default") {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	} else {
		# go to MultiDropSortHeader page
		$cgi->param(-name => "wherenext", -value => "MultiDropSortHeader");
	}
}

sub update_email_settings {
	my $cgi = shift;
	print qq(
	<h2>Finished</h2>
	<p>
	If we were really doing stuff here, this is the routine where
	we'd call the appropriate e-smith event to actually update the
	email settings.  Some of the values filled in by the user
	include:
	</p>
	);
	foreach my $f ( qw(retrieval_mode delegate_server) ) {
		print "<p><b>$f: </b>", $cgi->param($f), "</p>";
	}
	return 1;
}

# add phrases to be localised here

sub lexicon_fr {
	return {
		"foo" => "bar",
		"POP user account" => "compte d'utilisateur POP",
	};
}
