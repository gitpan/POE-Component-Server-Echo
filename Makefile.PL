use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# Blah!

WriteMakefile(
			  'NAME'	=> 'POE::Component::Server::Echo',
			  'PM'      => { 'Echo.pm' => '$(INST_LIBDIR)/Echo.pm',
				       },
			  'PREREQ_PM' => {
							  'POE'    => 0.06_07,
							  'Carp'   => 0,
							  'Socket' => 0,
							 },
			  'VERSION_FROM' => 'Echo.pm', # finds $VERSION
			  'dist' => { 'COMPRESS' => 'gzip --best' },
			 );
