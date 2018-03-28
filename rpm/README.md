# RPM installation

The goal is to build a new RPM to install the lpass CLI binary. The version found on EPEL and other repos is old.

## Build process

Build a base Centos 7 server and install the following packages:

```
sudo yum install -y openssl libcurl libxml2 pinentry xclip openssl-devel libxml2-devel libcurl-devel cmake gcc-c++ rpm-build asciidoc xsltproc
```

Download the source from https://github.com/lastpass/lastpass-cli and follow the build instructions. They are basically:

```
make
sudo make install
sudo make install-doc
```

When building 1.3.0, we observed the binary and bash completion files being installed, as well as the man page when install-doc was run.

## RPM process

The RPM process expects a tarball of the source. The following command collects all three of the previously menationed files.

```
mkdir -p ~/rpm/SOURCES
tar -czvf ~/rpm/SOURCES/lpass.tar.gz /usr/local/bin/lpass /usr/local/share/man/man1/lpass.1 /usr/share/bash-completion/completions/lpass
```

Prepare the spec file using the included template. Make sure to update the release number and the changelog. Copy the spec file to ~/rpm/SPECS/lpass.spec. Customize the tar and spec file for your needs.

Run rpmbuild:

```
cd ~/rpm
rpmbuild --define '_topdir '`pwd` --define 'dist .el7' -ba SPECS/lpass.spec
```

If you did everything correctly, you will have a new RPM at:

```
~/rpm/RPMS/x86_64/lastpass-cli-%{version}-%{release}.x86_64.rpm
```
