use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nifty::Config',
    license             => 'bsd',
    dist_author         => q{James Hunt <james@niftylogic.com>},
    dist_version_from   => 'lib/Nifty/Config.pm',
    build_requires => {
        'Test::More'      => 0,
        'Test::Deep'      => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'Hash::Merge'     => 0,
        'YAML::XS'        => 0,
        'perl'            => 5.006,
    },
    configure_requires  => { 'Module::Build' => 0.38 },
    add_to_cleanup      => [ 'Nifty-Config-*' ],
);

$builder->create_build_script();
