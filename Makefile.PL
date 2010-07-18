#!/usr/bin/env perl

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'App::OracleInfo',
    VERSION_FROM => "lib/App/OracleInfo.pm",
    ABSTRACT => 'Print some oracle informations',
    PREREQ_PM => {
        'DBI' => 0,
        'DBD::Oracle',
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/oracle_info' ],
);