%define      debug_package %{nil}

Name:        lastpass-cli
Version:     1.1.2
Summary:     Command line interface to LastPass.com.
URL:         https://github.com/lastpass/lastpass-cli

License:     GNU GENERAL PUBLIC LICENSE Version 2
Release:     1%{?dist}
Source0:     lpass.tar.gz
BuildRoot:   %(mktemp -ud %{_tmppath}/lpass-XXXXXX)
BuildArch:   x86_64

%description
Installs the lpass binary.

%prep
%setup -q -c

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT

mkdir -p -m0755 $RPM_BUILD_ROOT/usr
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local/bin

cp -p lpass $RPM_BUILD_ROOT/usr/local/bin/lpass

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, -)

/usr/local/bin/lpass

%changelog

* Sun Feb 19 2017 Dirk Tepe <tepeds@miamioh.edu> - 1.1.2-1
- Initial build of LastPass CLI 1.1.2 source