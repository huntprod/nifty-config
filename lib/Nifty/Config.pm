package Nifty::Config;
use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use Hash::Merge qw/merge/;
use File::Find qw/find/;
use base 'Exporter';
our @EXPORT = qw/
	read_configs
/;
our @EXPORT_OK = @EXPORT;

our $VERSION = '1.0.0';

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
	$config = merge(LoadFile($_), $config) for sort @files;
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

=back

=head1 AUTHOR

Written by James Hunt <james@niftylogic.com>

=cut
