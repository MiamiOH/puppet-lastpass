# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.
#

class lastpass (
  $manage_package = true,
  $package        = $lastpass::params::package,
  $lpass_home     = '$HOME/.lpass',
  $user           = 'root',
  $group          = undef,
  $config_dir     = undef,
  $username       = undef,
  $password       = undef,
  $agent_timeout  = undef,
  $sync_type      = undef,
  $auto_sync_time = undef,
) inherits lastpass::params {

  $_group = $group ? {
    undef   => $user,
    default => $group,
  }

  $_config_dir = $config_dir ? {
    undef   => $user ? {
      'root'  => "/${user}/.lpass",
      default => "/home/${user}/.lpass",
    },
    default => $config_dir,
  }

  unless $sync_type == undef {
    validate_re($sync_type, '^(auto|now|no)$',
    "Sync type ${sync_type} is not valid, use one of auto, now or no")
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

  lastpass::config {
    'username': value => $username, file => 'login';
    'password': value => $password, file => 'login';
  }

  if $password {
    lastpass::config { 'askpass': value => '/usr/local/bin/lpasspw' }
  }

  lastpass::config {
    'agent_timeout':  value => $agent_timeout;
    'sync_type':      value => $sync_type;
    'auto_sync_time': value => $auto_sync_time;
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => "export LPASS_HOME=${lpass_home}",
    shell   => 'absent',
  }
}
