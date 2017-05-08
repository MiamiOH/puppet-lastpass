#
# == Definition: lastpass::config
#
# Uses shellvar to add/alter/remove options in lpass
# configuation file.
# http://lastpass.github.io/lastpass-cli/lpass.1.html
#
# === Parameters
#
# [*name*]   - name of the parameter.
# [*ensure*] - present/absent/exported. defaults to present.
# [*value*]  - value of the parameter.
#
# === Requires
#
# - Class['lastpass']
#
# === Examples
#
#   lastpass::config { 'LPASS_AGENT_TIMEOUT':
#     ensure => present,
#     value  => 3600,
#   }
#
#   lastpass::config {
#     'agent_timeout':  value => 3600;
#     'auto_sync_time': value => 5;
#   }
#
#   lastpass::config { 'LPASS_AGENT_TIMEOUT':
#     ensure => absent,
#   }
#

define lastpass::config (
  $ensure = present,
  $value  = undef,
  $file   = 'env',
) {

  include '::lastpass'

  if $name =~ /(?i:^LPASS_)/ {
    $variable = upcase($name)
  } else {
    $variable = upcase("LPASS_${name}")
  }

  if ($value != undef) or ($ensure == 'absent') {
    ensure_resource('file', $lastpass::_config_dir, {
        ensure => directory,
        owner  => $lastpass::user,
        group  => $lastpass::_group,
        mode   => '0700',
    })

    ensure_resource('file', "${lastpass::_config_dir}/${file}", {
        ensure => file,
        owner  => $lastpass::user,
        group  => $lastpass::_group,
        mode   => '0600',
    })

    shellvar { "lastpass-config-${title}":
      ensure   => $ensure,
      target   => "${lastpass::_config_dir}/${file}",
      variable => $variable,
      value    => $value,
      require  => File["${lastpass::_config_dir}/${file}"],
    }
  }
}
