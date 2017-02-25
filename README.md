# puppet-lastpass

Puppet module to interact with the LastPass CLI.

https://github.com/lastpass/lastpass-cli

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with lastpass](#setup)
    - [What lastpass affects](#what-filebeat-affects)
    - [Setup requirements](#setup-requirements)
    - [Beginning with lastpass](#beginning-with-lastpass)
3. [Usage - Configuration options and additional functionality](#usage)
    - [Adding a prospector](#adding-a-prospector)
      - [Multiline Logs](#multiline-logs)
      - [JSON logs](#json-logs)
    - [Prospectors in hiera](#prospectors-in-hiera)
    - [Usage on Windows](#usage-on-windows)
4. [Reference](#reference)
    - [Public Classes](#public-classes)
    - [Private Classes](#private-classes)
    - [Public Defines](#public-defines)
5. [Limitations - OS compatibility, etc.](#limitations)
    - [Pre-1.9.1 Ruby](#pre-191-ruby)
    - [Using config_file](#using-config_file)
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

To ship log files through [logstash](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html#logstash-output):
```puppet
class { 'filebeat':
  outputs => {
    'logstash'     => {
     'hosts' => [
       'localhost:5044',
       'anotherserver:5044'
     ],
     'loadbalance' => true,
    },
  },
}

```

[Shipper](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html#configuration-shipper) and [logging](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html#configuration-logging) options can be configured the same way, and are documented on the [elastic website](https://www.elastic.co/guide/en/beats/filebeat/current/index.html).

### resources_deep_merge

- *Type*: rvalue

Returns a [deep-merged](#deep_merge) resource hash (hash of hashes).

*Examples:*

```puppet
    $tcresource_defaults = {
      ensure     => 'present',
      attributes => {
        driverClassName => 'org.postgresql.Driver',
      }
    }

    $tcresources = {
      'app1:jdbc/db1' => {
        attributes => {
          url      => 'jdbc:postgresql://localhost:5432/db1',
          userpass => 'user1:pass1',
        },
      },
      'app2:jdbc/db2' => {
        attributes => {
          url      => 'jdbc:postgresql://localhost:5432/db2',
          userpass => 'user2:pass2',
        },
      }
    }
```

When called as:

```puppet
    $result = resources_deep_merge($tcresources, $tcresource_defaults)
```

will return:

```puppet
    {
     'app1:jdbc/db1' => {
       ensure     => 'present',
       attributes => {
         url      => 'jdbc:postgresql://localhost:5432/db1',
         userpass => 'user1:pass1',
         driverClassName => 'org.postgresql.Driver',
       },
     },
     'app2:jdbc/db2' => {
       ensure     => 'present',
       attributes => {
         url      => 'jdbc:postgresql://localhost:5432/db2',
         userpass => 'user2:pass2',
         driverClassName => 'org.postgresql.Driver',
       },
     }
    }
```


## Reference
 - [**Public Classes**](#public-classes)
    - [Class: filebeat](#class-filebeat)
 - [**Private Classes**](#private-classes)
    - [Class: filebeat::config](#class-filebeatconfig)

### Public Classes

#### Class: `filebeat`

Installs and configures filebeat.

**Parameters within `filebeat`**
- `major_version`: [String] The major version of filebeat to install. Should be either undef, 1, or 5. (default 5 if 1 not already installed)

### Private Classes

#### Class: `filebeat::params`

Sets default parameters for `filebeat` based on the OS and other facts.

## Limitations
...

## Development

Pull requests and bug reports are welcome. If you're sending a pull request, please consider
writing tests if applicable.
