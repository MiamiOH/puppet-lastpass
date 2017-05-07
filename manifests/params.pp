# Class: lastpass::params
#
# This class manages parameters for the LastPass module
#

class lastpass::params {

  case $::osfamily {
    'RedHat': {
      if $::operatingsystemmajrelease != '7' {
        fail("Unsupported RedHat family version: ${::operatingsystemmajrelease}")
      }

      $package = 'lastpass-cli'

    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}")
    }
  }

}
