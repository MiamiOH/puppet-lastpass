%define      debug_package %{nil}

Name:        lastpass-cli
Version:     1.3.0
Summary:     Command line interface to LastPass.com.
URL:         https://github.com/lastpass/lastpass-cli

License:     GNU GENERAL PUBLIC LICENSE Version 2
Release:     1%{?dist}
Source0:     lpass.tar.gz
BuildRoot:   %(mktemp -ud %{_tmppath}/lpass-XXXXXX)
BuildArch:   x86_64

%description
Installs the lpass binary, man file and bash completion.

%prep
%setup -q -c

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT

mkdir -p -m0755 $RPM_BUILD_ROOT/usr
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local/bin
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local/share
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local/share/man
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/local/share/man/man1
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/share
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/share/bash-completion
mkdir -p -m0755 $RPM_BUILD_ROOT/usr/share/bash-completion/completions

cp -p /usr/local/bin/lpass $RPM_BUILD_ROOT/usr/local/bin/lpass
cp -p /usr/local/share/man/man1/lpass.1 $RPM_BUILD_ROOT/usr/local/share/man/man1/lpass.1
cp -p /usr/share/bash-completion/completions/lpass $RPM_BUILD_ROOT/usr/share/bash-completion/completions/lpass

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, -)

/usr/local/bin/lpass 
/usr/local/share/man/man1/lpass.1 
/usr/share/bash-completion/completions/lpass

%changelog

* Tue Mar 27 2018 Dirk Tepe <tepeds@miamioh.edu> - 1.3.0-1
- Update spec for CLI 1.3.0 release
- Add lpass man page and bash completion

* Sun Feb 19 2017 Dirk Tepe <tepeds@miamioh.edu> - 1.1.2-1
- Initial build of LastPass CLI 1.1.2 source