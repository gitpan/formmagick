#!/usr/bin/env perl 

BEGIN { 
	$^W = 1;
}

#use lib "/home/srl/web/public_html/perl/formmagick";
#chdir  "/home/srl/web/public_html/perl/formmagick/examples" or die "couldn't chdir to fm directory";

use strict;
use FormMagick;
use Data::Dumper;

my $xmlfilename = $ARGV[0] || "./testfm.xml";

my $fm = new FormMagick(
	TYPE => "file", 
	SOURCE => $xmlfilename,
	DEBUG => 1,
);

$fm->display();

$fm->add_lexicon(fr => lexicon_fr());
$fm->add_lexicon(en => lexicon_en());

# the post-event function for the FormMagick form. 
# takes a CGI::Persistent object as a parameter. 

sub submit_order {
    my $cgi = shift;
    my @params = $cgi->param();

    # do what you want with the data we got in. 
    print "<ul>\n";
    foreach my $param (@params) {
	my $value =  $cgi->param($param);
	print "<li>$param: $value\n";
    }
    print "</ul>\n";

    return 1;
}


sub my_groups {
    
    my $groups = {
	    Boston => "Boston.pm",
	    Melbourne => "Melbourne.pm",
	    London => "London.pm"};
    return $groups;
}

sub colors {
    
    my $colors = ['red', 'blue', 'green', 'orange', 'purple', 'yellow'];
    return $colors;
}

sub lexicon_en {
	return {
	"FormMagick demo application"
		=> "FormMagick demo application",
	"Personal details"
		=> "Personal details",
	"Your first name"
		=> "Your first name",
	"Your surname"
		=> "Your surname",
	"Choose a username"
		=> "Username",
	"Choose a group"
		=> "Group",
	"Your favorite number"
		=> "Your favorite number",
	"Your favorite color"
		=> "Your favorite color",
	"Your birthday"
		=> "your birthday",
	"Your favorite ISO country code"
		=> "Your favorite ISO country code",
	"Is your hair blue?"
		=> "Is your hair blue?",
	"Your favorite US state"
		=> "Your favorite US state",	
	"Your US zipcode"
		=> "Your US zipcode",
	"Payment details"
		=> "Payment details",
	"Credit card type"
		=> "Credit card type",
	"Credit card number"
		=> "Credit card number",
	"Expiry date (MM/YY)"
		=> "Expiration date (MM/YY)",
	};
}

sub lexicon_fr {
	return {
	"FormMagick demo application"
		=> "Application de demonstrater FormMagick",
	"Personal details"
		=> "Données personnel",
	"Your first name"
		=> "Prénom",
	"Your surname"
		=> "Nom",
	"Choose a username"
		=> "Choisissez un nom d'utilisateur",
	"Choose a group"
		=> "Choisissez une groupe",
	"Your favorite number"
		=> "Votre numero favori",
	"Your favorite color"
		=> "Votre couleur prefere",
	"Your birthday"
		=> "Votre anniversaire",
	"Your favorite ISO country code"
		=> "Votre code de pays prefere",
	"Is your hair blue?"
		=> "Es-ce que votre cheveux bleu?",
	"Your favorite US state"
		=> "Votre prefere etat des Etats-Unis",	
	"Your US zipcode"
		=> "Votre code de poste",
	"Payment details"
		=> "Données de paiement",
	"Credit card type"
		=> "Genre de carte de paiement",
	"Credit card number"
		=> "Numéro de carte de paiement",
	"Expiry date (MM/YY)"
		=> "Date d'expiration (MM/AA)",
	};
}

