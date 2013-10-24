#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

BEGIN { use_ok 'Nifty::Config'; }
my $config;

$config = read_config("t/data/one/file.yml");
cmp_deeply $config, {
		name => 'file.yml',
		type => 'file'
	}, "Read a single configuration file";

$config = read_config([
		"t/data/try/missing.yml",   # file doesn't exist
		"/not/at/all/valid.yml",
		"t/data/try",               # is a directory
		"t/data/try/file.yml",      # this one exists
		"t/data/try/file2.yml",     # skipped
	]);
cmp_deeply $config, {
		from => 'file.yml'
	}, "Found the first existent file";

$config = read_config([
		"t/data/try/file*" # glob()!
	]);
cmp_deeply $config, {
		from => 'file.yml' # only the first glob result matched...
	}, "Used glob() to find the files";

$config = read_config();
ok !$config, "failed to read config from undef file";
$config = read_config([]);
ok !$config, "failed to read config from empty fileset";

throws_ok { read_config(undef, raise_errors => 1) }
	qr{read_config: no config files specified}i,
	"missing files error thrown under raise_errors";
throws_ok { read_config([], raise_errors => 1) }
	qr{read_config: no config files specified}i,
	"missing files ([]) error thrown under raise_errors";


$config = read_config("t/data/enoent");
ok !$config, "failed to read config from bad file";

throws_ok { read_config("t/data/enoent", raise_errors => 1) }
	qr{read_config: t/data/enoent: no such file or directory}i,
	"ENOENT error is thrown under raise_errors";


$config = read_config("t/data/all");
ok !$config, "failed to read config from a non-file";

throws_ok { read_config("t/data/all", raise_errors => 1) }
	qr{read_config: t/data/all: not a regular file}i,
	"ENOTFILE error is thrown under raise_errors";


$config = read_config("t/data/multi.conf", chain => "t/data/multi.d");
cmp_deeply $config, {
		toplevel => 'multi.conf supplied it',
		l1 => { from => 'multi.d/l1' },
		l2 => { from => 'multi.d/l2' },
	}, "Chained to conf.d-style directory, using literal config";

$config = read_config("t/data/multi2.conf", chain => \"confdir");
cmp_deeply $config, {
		toplevel => 'multi2.conf supplied it this time',
		confdir  => "t/data/multi.d",
		l1 => { from => 'multi.d/l1' },
		l2 => { from => 'multi.d/l2' },
	}, "Chained to conf.d-style directory, using bootstrap config";

$config = read_config("t/data/multi.conf", chain => "/enoent");
cmp_deeply $config, {
		toplevel => 'multi.conf supplied it',
	}, "Chained to non-existent conf.d";
throws_ok {
	read_config("t/data/multi.conf",
		chain => "/enoent",
		raise_errors => 1) }
	qr{read_configs: /enoent: no such file or directory}i,
	"ENOTDIR thrown for chained directory load";

done_testing;
