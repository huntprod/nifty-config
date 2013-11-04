package Nifty::Config;
use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use Hash::Merge qw/merge/;
use File::Find qw/find/;
use base 'Exporter';
our @EXPORT = qw/
	read_config
	read_configs
/;
our @EXPORT_OK = @EXPORT;

our $VERSION = '1.1.1';

sub read_config
{
	my ($files, %options) = @_;
	$files = [$files] if $files and ! ref($files);

	if ($options{raise_errors}) {
		die "read_config: no config files specified\n"
			unless $files and @$files;
	} else {
		return undef unless $files and @$files;
	}

	my $last;
	for my $file (map { glob($_) } @$files) {
		$last = $file;
		next unless -f $file and -r $file;

		my $config = eval { LoadFile($file) };
		if ($@) {
			die $@ if $options{raise_errors};
			return undef;
		}

		# resolve the chained stage2 config
		if (ref($options{chain}) eq 'SCALAR') {
			# does not support non-toplevel chain key
			$options{chain} = $config->{${$options{chain}}};
		}

		if ($options{chain}) {
			# load stage 2 configuration, from a directory
			my $stage2 = read_configs($options{chain}, %options);
			$config = merge($stage2, $config) if $stage2;
		}
		return $config;
	}

	# failed.
	return undef unless $options{raise_errors};
	die "read_config: $last: no such file or directory"
		unless -e $last;
	die "read_config: $last: not a regular file"
		unless -f $last;
}

sub read_configs
{
	my ($dir, %options) = @_;
	if ($options{raise_errors}) {
		die "read_configs: no root directory specified\n"
			unless $dir;
		die "read_configs: $dir: no such file or directory\n"
			unless -e $dir;
		die "read_configs: $dir: not a directory\n"
			unless -d $dir;
	} else {
		return undef unless $dir and -r $dir and -d $dir;
	}

	my @files = ();
	find({
		wanted => sub {
			return unless -f $_;
			return if substr($_, 0, 1) eq '.' and !$options{hidden};
			return if $options{match} && $_ !~ $options{match};
			push @files, $File::Find::name;
		},
	}, $dir);

	my $config = {};
	eval { $config = merge(LoadFile($_), $config) for sort @files };
	if ($@) {
		die $@ if $options{raise_errors};
		return undef;
	}
	$config;
}

1;

=head1 NAME

Nifty::Config - Configuration Routines for NiftyLogic code

=head1 FUNCTIONS

=head2 read_configs($dir, [%options])

Read a single configuration, split out across several files in one
directory sub-hierarchy.  The %options hash can be used to govern
what files are considered for inclusion in the conglomerate
configuration.

Configuration files are expected to be in YAML, since that's the
only sane configuration file format these days.

The following options are supported:

=over

=item B<match>

A regular expression for matching individual file names.  If
specified, only files that match this expression will be parsed.

=item B<hidden>

A boolean that enables read_configs() to consider hidden files
for inclusion, regardless of what matches.

=item B<raise_errors>

Causes read_configs to die when errors are encountered, rather than
just returning undef.  Useful for those life-or-death configuration
situations.

=back

=head2 read_config($fileset, [%options])

Read configuration from a single file.  B<$fileset> can be an array
reference, which will cause read_config to try each file path in the
set, until it find a readable, regular file.

For example, to try local files, then fall back to distributed files:

    my $c = read_config([
                          '/etc/local/site.conf',
                          '/etc/local/app.conf',
                          '/etc/app.conf',
                          '/etc/app.conf.dist'
                        ]);

You can also use ~ and other UNIX shell-isms, since we pass each
filename to glob():

    my $c = read_config(['~/.apprc', '/etc/app.*'])

Configuration files are expected to be in YAML, since no one in their
right mind uses XML or JSON for config files...

The following options are supported:

=over

=item B<chain>

Instructs read_config to call read_configs(), and merge in the
configuration found in a sub-directory.  This is to support the wildly
useful I<conf.d> approach to modular configuration, where a single
fixed configuration file is augmented by an open directory where other
packages can drop their slice of the config.

Usage varies depending on whether the value for B<chain> is a simple
scalar, or a scalar reference.

For a simple scalar, i.e.:

    my $c = read_config('/etc/test.conf',
                        chain => "/etc/test.d");

read_config interprets the value (C</etc/test.d>) as the full path
of the root directory containing the modular configuration.

If B<chain> is a scalar reference, as in:

    my $c = read_config('/etc/test.conf',
                        chain => \"confdir");

Then the value is interpreted as the name of a top-level key in
the first configuration file, and the value of the directory is
pulled from there.  (Note the leading backlash of the literal
scalar ref notation)

To illustrate the power of this even further, consider the following
configuration file, B</etc/test.conf>:

    ---
    # /etc/test.conf
    app:     some-web-app
    port:    8181
    confdir: /etc/test.d

The following code would then transparently load in the above
configuration, and then chain-load all the files under /etc/test.d:

    my $c = read_config('/etc/test.conf',
                        chain => \"confdir");

=back

=head1 AUTHOR

Written by James Hunt <james@niftylogic.com>

=cut
