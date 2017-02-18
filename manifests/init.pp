# Class: lastpass
#
# This class installs the LastPass CLI and provides functions to interact with it.

class lastpass (
  $package  = $lastpass::params::package,
  $username = undef,
  $password = undef,
  $lpass_home = '/root/.lpass'
) inherits lastpass::params {

  package { $package:
    ensure => present,
  }

  file { "/usr/local/bin/lpasspw":
    ensure => file,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/lpasspw",
  }

  # TODO find a real place to put this file
  file { "${lpass_home}/pw":
    ensure  => file,
    mode    => '0400',
    content => inline_template("<%= @password %>")
  }

  profiled::script { 'lpass.sh':
    ensure  => file,
    content => "export LPASS_ASKPASS=/usr/local/bin/lpasspw
                export LPASS_HOME=${lpass_home}",
    shell   => 'absent',
  }

  # Notes:
  #
  # 1. Module installation will run 'lpass login' to initialize the 
  #    home directory.
  #    
  # 2. Credentials will be stored in a defined location (yaml) and must
  #    exist before module will install.
  #    
  # 3. Script to be used as LPASS_ASKPASS, needs to know what lpass
  #    will send as prompt, read from configured file and output
  #    to stdout. Should be able to read password and possibly code
  #    if possible.
  #    
  # 4. Puppet function to read a secure note
  # 
  #    lastpass_read_note(GROUP, NAME)
  #    
  #    This will mimic the cache_data(PATH, NAME) function. The lpass
  #    command can show based on unique NAME, but it makes sense to
  #    enforce GROUP and NAME by:
  #    
  #    lpass ls GROUP
  #    (verify NAME is found in list)
  #    lpass show --notes NAME (or possibly UNIQUENAME found in previous step)
  #    
  #    Always expect the note content to be YAML, even for a single password.
}
