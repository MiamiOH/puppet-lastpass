# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.

class lastpass (
  $package             = $lastpass::params::package,
  $home                = undef,
  $lpass_home          = "\$HOME/.lpass",
  $lpass_agent_timeout = 3600,
  $username            = undef,
  $password            = undef,
) inherits lastpass::params {

  if $password and !$home {
    fail('Cannot set lastpass::password without lastpass::home')
  }

  if $username and !$home {
    fail('Cannot set lastpass::username without lastpass::home')
  }

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

  if $home {
    file { $home:
      ensure => directory,
      mode   => '0600',
    }
  }

  if $password {
    file { "${home}/pw":
      ensure  => file,
      mode    => '0400',
      content => $password,
      require => File[$home],
    }
  }

  if $username {
    file { "${home}/user":
      ensure  => file,
      mode    => '0400',
      content => $username,
      require => File[$home],
    }
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => template("${module_name}/lpass.sh.erb"),
    shell   => 'absent',
  }

}
