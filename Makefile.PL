use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


WriteMakefile(
    'NAME'		=> 'FormMagick',
    'VERSION_FROM'	=> 'FormMagick.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
				Persistence::Object::Simple => 0.47,
				XML::Parser => 2.30,
				Text::Template => 1.23,
				Locale::Maketext => 0.18,
				Time::ParseDate => '00.01_03_01',
				Geography::States => 1.3,
				Locale::Country => 1.02,
	# the following are nasty modules that aren't nicely CPANable
				# CGI::Persistent => 0.21
				# Business::CreditCard => 0.21,
			},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FormMagick.pm', # retrieve abstract from module
       AUTHOR     => 'Kirrily "Skud" Robert <skud@infotrope.net>') : ()),
);

