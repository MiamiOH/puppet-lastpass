# Class: lastpass::params
#
# This class manages parameters for the LastPass module
#

class lastpass::params {

  case $::osfamily {
    'redhat': {
      if $::operatingsystemmajrelease != '7' {
        fail('Unsupported redhat family version')
      }

      $package = 'lastpass-cli'

    }
    default: {
      fail('Unsupported osfamily')
    }
  }

}
