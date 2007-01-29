use inc::Module::Install;
name 'POE-Component-Server-Echo';
author 'Chris Williams <chris@bingosnet.co.uk>';
license 'perl';
version_from 'lib/POE/Component/Server/Echo.pm';
requires 'Carp'   => 0;
requires 'Socket' => 0;
requires 'POE' => 0.38;
WriteAll();
