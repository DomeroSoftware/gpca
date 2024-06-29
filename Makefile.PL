use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'gpca',
    VERSION_FROM => 'lib/gpca.pm',  # Path to the main module file
    AUTHOR       => 'OnEhIppY, Domero, Groningen',
    ABSTRACT     => 'Permanent Compressed Archive',
    LICENSE      => 'perl',

    PREREQ_PM    => {
        'strict'            => 0,
        'warnings'          => 0,
        'Exporter'          => 0,
        'gfio'              => 0,
        'Compress::Zlib'    => 0,
    },

    dist          => { COMPRESS => 'gzip', SUFFIX => 'gz', },
    clean         => { FILES => 'gpca-*' },
);
