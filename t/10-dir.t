#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

BEGIN { use_ok 'Nifty::Config' };
my $config;

$config = read_configs("t/data/all");
cmp_deeply $config, {
		first  => 1,
		second => 2,
	}, "Read all files in a directory";


$config = read_configs("t/data/deep");
cmp_deeply $config, {
		l1     => 'yay',
		level2 => 2,
		a      => 'dir2',
		b      => 'dir2',
	}, "Read configuration several directories deep";


$config = read_configs("t/data/merge");
cmp_deeply $config, {
		key => "override"
	}, "Merge precedence prefers later values";


$config = read_configs("t/data/match", match => qr/^\S\S\.yml$/);
cmp_deeply $config, {
		aa => 'from aa.yml'
	}, "Read only configuration files that match";


qx(rm -rf t/data/empty; mkdir -p t/data/empty);
$config = read_configs("t/data/empty");
cmp_deeply $config, {}, "Read empty directory";


$config = read_configs("t/data/hidden");
cmp_deeply $config, {
		public => "yes"
	}, "Only read non-hidden files";

$config = read_configs("t/data/hidden", hidden => 1);
cmp_deeply $config, {
		public => "yes",
		hidden => "yes",
	}, "Read hidden files with `hidden' options";


$config = read_configs();
ok !$config, "failed to read config from undef directory";

throws_ok { read_configs(undef, raise_errors => 1) }
	qr{read_configs: no root directory specified}i,
	"missing directory error thrown under raise_errors";


$config = read_configs("t/data/enoent");
ok !$config, "failed to read config from bad directory";

throws_ok { read_configs("t/data/enoent", raise_errors => 1) }
	qr{read_configs: t/data/enoent: no such file or directory}i,
	"ENOENT error is thrown under raise_errors";


$config = read_configs("t/data/all/first.yml");
ok !$config, "failed to read config from a single file";

throws_ok { read_configs("t/data/all/first.yml", raise_errors => 1) }
	qr{read_configs: t/data/all/first\.yml: not a directory}i,
	"ENOTDIR error is thrown under raise_errors";

$config = read_configs("t/data/not-yaml");
ok !$config, "failed to read dir with non-YAML file";

throws_ok { read_configs("t/data/not-yaml", raise_errors => 1) }
	qr{YAML::XS::Load Error}i,
	"Bad YAML error thrown under raise_errors";

done_testing;
