# puppet-lastpass

Puppet module to interact with the LastPass CLI.

https://github.com/lastpass/lastpass-cli

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with lastpass](#setup)
    - [What lastpass affects](#what-lastpass-affects)
    - [Setup requirements](#setup-requirements)
    - [Beginning with lastpass](#beginning-with-lastpass)
3. [Usage - Configuration options and additional functionality](#usage)
    - [Setting configuration options](#setting-configuration-options)
    - [Automated login](#automated-login)
    - [lastpass_item_read](#lastpass_item_read)
4. [Reference](#reference)
    - [Public Classes](#public-classes)
    - [Private Classes](#private-classes)
    - [Public Defines](#public-defines)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

The `lastpass` module installs and configures the [LastPass CLI](https://github.com/lastpass/lastpass-cli) maintained) by LastPass. The module installs the CLI and some supporting scripts to allow any user to run the lpass commands from the shell. The module also provides a Puppet function which enables access to a LastPass vault from within Puppet.

## Setup

### What lastpass affects

The `lastpass` module installs the LastPass CLI package, supporting shell scripts and a profile script to set the environment. The functions provided by the module are available to Puppet without including the lastpass class.

### Setup Requirements

The `lastpass` module only supports Centos 7 at this time. The module depends on [`puppetlabs/stdlib`](https://forge.puppetlabs.com/puppetlabs/stdlib), and on [`unibet/profiled`](https://forge.puppet.com/unibet/profiled).

The module assumes that LastPass CLI is available as an RPM from a configured repository. At this time, the most recent version of the CLI available is 0.9.0, which does not contain features required by the module. You can disable package management in the module and install an appropriate version of the LastPass CLI (>=1.1.2) through any means you want.

### Beginning with lastpass

TBD

## Usage

Basic usage is to simply require the class:
```puppet
class { 'lastpass': }

```

Once installed, the lpass command is available as documented on the [user guide](https://lastpass.github.io/lastpass-cli/lpass.1.html).

### Setting configuration options

Lastpass is configured with environment variables. You can optionally set them in $LASTPASS_HOME/env.  
A defined type is provided to manage these settings.

```puppet
lastpass::config { 'LPASS_AGENT_TIMEOUT':
  ensure => present,
  value  => 3600,
}

lastpass::config {
  'agent_timeout':  value => 3600;
  'auto_sync_time': value => 5;
}

lastpass::config { 'LPASS_AGENT_TIMEOUT':
  ensure => absent,
}
```

### Automated login

The module provides two helper scripts to facilitate automated login for unattended systems. These scripts require the LastPass username and password be stored in $LASTPASS_HOME/login. The module will create this if the username and password parameters are provided, or this can be created manually for the desired user. The default value of $LASTPASS_HOME is '$HOME/.lpass'.

The lpasslogin script will read the $LASTPASS_HOME/login file and run 'lpass login $LPASS_USERNAME'. If $LASTPASS_HOME/login is present, the profile script installed by the module will set $LASTPASS_ASKPASS to the lpasspw script, which reads $LASTPASS_HOME/login and prints $LASTPASS_PASSWORD it to STDOUT in response to the CLI.

The lastpass class can configure a user for automated login during provisioning. To configure the root user for example:
```puppet
class { 'lastpass':
  user          => 'root',
  group         => 'root',
  config_dir    => "${::root_home}/.lpass",
  username      => 'lpassuser@example.com',
  password      => 'lpass_master_pw',
  agent_timeout => 0,
}

```

The lastpass::username and lastpass::password params can be left out and manually created as described above.

### lastpass_item_read

- *Type*: rvalue

Returns a LastPass vault item as a hash. The result of `lpass show` is converted to hash and returned with the LastPass field names as keys. A Puppet::ParseError error is raised if the specified item does not exist.

*Examples:*

```
  php\db/courselist_development [id: 7699093785340133506]
  Username: cf_opencourse
  Password: secr3t
  Alias:
  SID: DEVL
  Database: DEVL
  Port:
  Hostname:
  Type: oracle
  NoteType: Database
  Notes: db notes
  go here
```

When called as:

```puppet
    $config = lastpass_item_read('php\db', 'courselist_development')
```

will return:

```puppet
    {
      'Username' => 'cf_opencourse',
      'Password' => 'secr3t',
      'Alias' => '',
      'SID' => 'DEVL',
      'Database' => 'DEVL',
      'Port' => '',
      'Hostname' => '',
      'Type' => 'oracle',
      'NoteType' => 'Database',
      'Notes' => 'db notes
go here'
    }
```

### lastpass_item_add

- *Type*: rvalue

Uses the lpass add command to create a new item containing the provided data. Returns the newly created item.

*Examples:*

When called as:

```puppet
    $item_data = {'username' => 'bob', password => 'secr3t'}
    $new_item = lastpass_item_add('php\db', 'courselist_development', $item_data)
```

Will create the item as a generic note, saving the data in the Notes field as YAML. The new object will be returned consistent with the handling of generic notes.

## Reference
 - [**Public Classes**](#public-classes)
    - [Class: lastpass](#class-lastpass)
 - [**Private Classes**](#private-classes)
    - [Class: lastpass::params](#class-lastpassparams)

### Public Classes

#### Class: `lastpass`

Installs and configures LastPass CLI.

**Parameters within `lastpass`**
- `manage_package`: [Boolean] Manage the LastPass CLI package. You must configure the appropriate repo. Defaults to true.
- `package`: [String] The name of the LastPass CLI package to install. Defaults to 'lastpass-cli'.
- `lpass_home`: [String] The string to set as the $LASTPASS_HOME value in the profile script. Should work for any logged in user. Defaults to '$HOME/.lpass'.
- `user`: [String] The user to be configured for non-interactive lpass use. Requires that lastpass::config_dir and lastpass::group be set. The module does NOT create this user.
- `group`: [String] The group that will own lastpass::config_dir.
- `config_dir`: [String] A valid path corresponding to $LASTPASS_HOME for lastpass::user. The username and password will be written to the corresponding files at this location. Defaults to undef.
- `username`: [String] The LastPass username for automated login. Requires the config_dir parameter. Defaults to undef.
- `password`: [String] The LastPass password for automated login. Requires the config_dir parameter. Defaults to undef.
- `agent_timeout`: [Integer] The agent timeout in seconds after which relogin is required. Setting this to 0 disables the timeout. Defaults to lpass default of 3600.
- `sync_type`: [string] The sync option value to use with lpass commands which support sync. Must be one of 'auto', 'now', or 'no'. Defaults to auto.
- `auto_sync_time`: [Integer]  Defaults to lpass default of 5.

### Private Classes

#### Class: `lastpass::params`

Sets default parameters for `lastpass` based on the OS and other facts.

## Limitations

The only currently support operating system is CentOS 7.

## Development

Pull requests and bug reports are welcome. If you're sending a pull request, please consider
writing tests if applicable.
