#!/usr/bin/perl -w

use Locale::Maketext;

package FormMagick::L10N;
@ISA = qw(Locale::Maketext);

1;

=pod
=head1 NAME

FormMagick::L10N - localization routines for FormMagick

=head1 SYNOPSIS

  use FormMagick::L10N;

=head1 DESCRIPTION

L10N (Localisation) is the name given to the process of providing
translations into another language.  The previous step to this is I18N
(internationalisation) which is the process of making an application
ready to accept the translations.

We've done the work of I18N for you, so all you have to do is provide
translations for your apps.

FormMagick uses the C<Locale::Maketext> module for L10N.  It stores its
translations for each language in a hash like this:

  %Lexicon = (
	"Hello"		=> "Bonjour",
	"Click here"	=> "Appuyez ici"
  );

You can add your own entries to any language lexicon using the
C<add_lexicon()> method (see C<FormMagick> for how to call that method).

Localisation preferences are picked up from the HTTP_ACCEPT_LANGUAGE 
environment variable passed by the user's browser.  In Netscape, you set
this by choosing "Edit, Preferences, Navigator, Languages" and then
choosing your preferred language.

Localisation is performed on:

=over 4

=item *

Form titles

=item *

Page titles and descriptions

=item *

Field labels and descriptions

=item *

Validation error messages

=back

If you wish to localise other textual information such as your HTML 
Templates, you will have to explicitly call the l10n routines.

=head1 SEE ALSO

The general documentation for FormMagick (C<perldoc FormMagick>)

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut
