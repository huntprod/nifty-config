# nifty-config.spec

#############################

Name: perl-Nifty-Config
Version: %{_version}
Release: %{_release}
License: proprietary
Summary: Configuration Routines

Source: %{_dist}.tar.gz
BuildArch: noarch

Requires: perl(Exporter)
Requires: perl(File::Find)
Requires: perl(Hash::Merge)
Requires: perl(YAML::XS)

BuildRequires: perl(Exporter)
BuildRequires: perl(File::Find)
BuildRequires: perl(Hash::Merge)
BuildRequires: perl(Module::Build)
BuildRequires: perl(Test::Deep)
BuildRequires: perl(Test::Exception)
BuildRequires: perl(Test::More)
BuildRequires: perl(YAML::XS)


%description
Nifty::Config provides common, tested routines for dealing
with configuration of modules, applications and one-off scripts.

#############################

%prep
%setup -q -n %{_dist}

%build
%{__perl} Build.PL INSTALLDIRS=vendor
./Build && ./Build test

%install
# recreate build root
[ %{buildroot} != '/' ] && rm -rf %{buildroot}
mkdir -p %{buildroot}

#install into build root
./Build destdir=%{buildroot}/ install

# remove silly files
find %{buildroot} -name 'perllocal.pod' -o -name '.packlist' | xargs -r rm

# force compression of man pages
/usr/lib/rpm/brp-compress

# generate files list
find %{buildroot} -type f | sed -e "s@%{buildroot}/@/@" > .rpm_files

%clean
./Build realclean


#############################

%files -f .rpm_files
%defattr(-, root, root)

# vim:ft=spec
