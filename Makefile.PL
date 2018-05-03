#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    # INSTALLDIRS         => 'vendor',
    # INSTALLVENDORSCRIPT => '/var/www/memorix.noc.ams-ix.net/production/content/rts',
    # INSTALLVENDORBIN    => '/var/www/memorix.noc.ams-ix.net/production/content/rts',
    NAME                => 'M6::App::Config',
    VERSION_FROM        => 'lib/M6/App/Config.pm',
    AUTHOR              => 'Laszlo Bogardi <laszlo.bogardi@ams-ix.net>',
    EXE_FILES           => [ qw() ],
    BUILD_REQUIRES      => {},
    PREREQ_PM           => {
        'YAML::AppConfig'    => '0.16',
        'YAML::XS'           => '0.33',
    },
);
