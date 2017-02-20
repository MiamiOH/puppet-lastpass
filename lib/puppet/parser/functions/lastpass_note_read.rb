require 'fileutils'
require 'yaml'
# require 'etc'

# Retrieves from a LastPass secure note
#
# Useful for having data that is managed via LastPass and shared with Puppet.
#
# Usage: lastpass_note_read(folder, name)
# Example: $db_config = lastpass_note_read('oracle/db', 'appuser')
Puppet::Parser::Functions.newfunction(:lastpass_note_read, :type => :rvalue) do |args|
  raise Puppet::ParseError, 'Usage: lastpass_note_read(folder, name)' unless args.size == 2

  folder = args[0]
  raise Puppet::ParseError, 'Must provide folder' if folder.empty?

  name = args[1]
  raise Puppet::ParseError, 'Must provide data name' if name.empty?

  username = lookupvar('lastpass::username')

  cmd = `which lpass`
  raise Puppet::ParseError, 'lpass command not found' if cmd.empty?
  version = `lpass --version`.strip
  raise Puppet::ParseError, "unexpected lpass version: #{version}" unless version =~ /v1.1.2$/

  # TODO consider how sync should be handled
  
  status = `lpass status`.strip

  if $?.exitstatus != 0
    if status == 'Not logged in.'
      login_result = `lpass login #{username}`
      raise Puppet::ParseError, "error: lpass login: #{login_result}" unless login_result =~ /^Success:/
    else
      raise Puppet::ParseError, "error: lpass status: #{status}"
    end
  end

  ls_result = `lpass ls '#{folder}'`
  if $?.exitstatus != 0
    raise Puppet::ParseError, "error: lpass ls '#{folder}': #{status}"
  end

  ls_result =~ /#{Regexp.escape(folder)}\/#{Regexp.escape(name)} \[id: ([^\]]+)\]/
  id = Regexp.last_match(1)
  unless id
    raise Puppet::ParseError, "error: unable to find id for '#{folder}/#{name}' in :\n#{ls_result}"
  end

  show_result = `lpass show '#{id}'`
  if $?.exitstatus != 0
    raise Puppet::ParseError, "error: lpass show '#{folder}/#{name}' [id: #{id}]: #{status}"
  end

  puts show_result

  note = YAML.load(show_result)
  # TODO if yaml load fails, return raw content
  # TODO return YAML content if unknown type

  case note['NoteType']

    when 'Database'
      content = {
        'username' => note['Username'],
        'password' => note['Password'],
        'sid' => note['SID'],
        'database' => note['Database'],
        'type' => note['Type'],
      }

    else
      content = nil

  end

  content
end
