# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.

class lastpass (
  $manage_package     = true,
  $package            = $lastpass::params::package,
  $lpass_home         = "\$HOME/.lpass",
  $user               = undef,
  $group              = undef,
  $user_home          = undef,
  $user_username      = undef,
  $user_password      = undef,
  $user_agent_timeout = 3600,
) inherits lastpass::params {

  if $user and !$user_home {
    fail('Missing lastpass::user_home for lastpass::user')
  }
  
  if $user and !$group {
    fail('Missing lastpass::group for lastpass::user')
  }

  if $user_home and !$user {
    fail('Missing lastpass::user for lastpass::user_home')
  }

  if $user_password and !$user_home {
    fail('Cannot set lastpass::user_password without lastpass::user_home')
  }

  if $user_username and !$user_home {
    fail('Cannot set lastpass::user_username without lastpass::user_home')
  }

  if $manage_package {
    package { $package:
      ensure => present,
    }
  }

  file { '/usr/local/bin/lpasspw':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "puppet:///modules/${module_name}/lpasspw",
  }

  file { '/usr/local/bin/lpasslogin':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "puppet:///modules/${module_name}/lpasslogin",
  }

  if $user_home {
    file { $user_home:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0600',
    } ->

    file { "${user_home}/env":
      ensure  => file,
      content => template("${module_name}/user_env.erb"),
    }
  }

  if $user_password {
    file { "${user_home}/pw":
      ensure  => file,
      mode    => '0400',
      content => $user_password,
      require => File[$user_home],
    }
  }

  if $user_username {
    file { "${user_home}/user":
      ensure  => file,
      mode    => '0400',
      content => $user_username,
      require => File[$user_home],
    }
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => template("${module_name}/lpass.sh.erb"),
    shell   => 'absent',
  }

}
