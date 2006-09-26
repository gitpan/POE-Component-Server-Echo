#use ExtUtils::MakeMaker;
use inc::Module::Install;

author 'Chris Williams <chris@bingosnet.co.uk>';
license 'perl';

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
