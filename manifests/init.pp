# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.

class lastpass (
  $manage_package      = true,
  $package             = $lastpass::params::package,
  $lpass_home          = '$HOME/.lpass',
  $user                = undef,
  $group               = undef,
  $config_dir          = undef,
  $user_username       = undef,
  $user_password       = undef,
  $user_agent_timeout  = 3600,
  $user_sync_type      = 'auto',
  $user_auto_sync_time = undef,
) inherits lastpass::params {

  if $user and !$config_dir {
    fail('Missing lastpass::config_dir for lastpass::user')
  }

  if $user and !$group {
    fail('Missing lastpass::group for lastpass::user')
  }

  if $config_dir and !$user {
    fail('Missing lastpass::user for lastpass::config_dir')
  }

  if $user_password and !$config_dir {
    fail('Cannot set lastpass::user_password without lastpass::config_dir')
  }

  if $user_username and !$config_dir {
    fail('Cannot set lastpass::user_username without lastpass::config_dir')
  }

  validate_re($user_sync_type, '^(auto|now|no)$',
  "Sync type ${user_sync_type} is not valid, use one of auto, now or no")

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

  if $config_dir {
    file { $config_dir:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0600',
    } ->

    file { "${config_dir}/env":
      ensure  => file,
      content => template("${module_name}/user_env.erb"),
    }
  }

  if $user_password {
    file { "${config_dir}/pw":
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0600',
      content => $user_password,
      require => File[$config_dir],
    }
  }

  if $user_username {
    file { "${config_dir}/user":
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0644',
      content => $user_username,
      require => File[$config_dir],
    }
  }

  if $user_sync_type {
    file { "${config_dir}/sync":
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0644',
      content => $user_sync_type,
      require => File[$config_dir],
    }
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => template("${module_name}/lpass.sh.erb"),
    shell   => 'absent',
  }

}
