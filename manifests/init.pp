# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.

class lastpass (
  $package       = $lastpass::params::package,
  $home          = '/root/.lpass',
  $agent_timeout = 3600,
  $username      = undef,
  $password      = undef,
) inherits lastpass::params {

  package { $package:
    ensure => present,
  }

  file { '/usr/local/bin/lpasspw':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "puppet:///modules/${module_name}/lpasspw",
  }

  file { $home:
    ensure => directory,
    mode   => '0600',
  }

  file { "${home}/pw":
    ensure  => file,
    mode    => '0400',
    content => $password,
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => template("${module_name}/lpass.sh.erb"),
    shell   => 'absent',
  }

}
