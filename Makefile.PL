use ExtUtils::MakeMaker;

WriteMakefile(
			  'NAME'	=> 'POE::Component::Server::Echo',
			  'PREREQ_PM' => {
							  'POE'    => 0.06_07,
							  'Carp'   => 0,
							  'Socket' => 0,
							 },
			  'VERSION_FROM' => 'lib/POE/Component/Server/Echo.pm',
			  'dist' => { 'COMPRESS' => 'gzip --best' },
			 );
