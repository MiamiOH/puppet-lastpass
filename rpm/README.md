# RPM installation

The goal is to build a new RPM to install the lpass CLI binary. The version found on EPEL and other repos is old.

## Build process

Build a base Centos 7 server and install the following packages:

```
sudo yum install -y openssl libcurl libxml2 pinentry xclip openssl-devel libxml2-devel libcurl-devel cmake gcc-c++ rpm-build
```

Download the source from https://github.com/lastpass/lastpass-cli and follow the build instructions. They are basically:

```
cmake . && make
sudo make install
```

When building 1.1.2, the only observed file being installed was the lpass binary.

## RPM process

The RPM process expects a tarball of the source. 

```
mkdir -p ~/rpm/SOURCES
cd /usr/local/bin
tar -czvf ~/rpm/SOURCES/lpass.tar.gz lpass
```

Prepare the spec file using the included template. Make sure to update the release number and the changelog. Copy the spec file to ~/rpm/SPECS/lpass.spec.

Run rpmbuild:

```
cd ~/rpm
rpmbuild --define '_topdir '`pwd` --define 'dist .el7' -ba SPECS/lpass.spec
```

If you did everything correctly, you will have a new RPM at:

```
~/rpm/RPMS/x86_64/lastpass-cli-1.1.2-%{release}.x86_64.rpm
```
