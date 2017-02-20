require 'fileutils'
require 'yaml'
require 'English'
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

  # TODO: consider how sync should be handled

  status = `lpass status`.strip

  if $CHILD_STATUS.exitstatus != 0
    if status == 'Not logged in.'
      login_result = `lpass login #{username}`
      raise Puppet::ParseError, "error: lpass login: #{login_result}" unless login_result =~ /^Success:/
    else
      raise Puppet::ParseError, "error: lpass status: #{status}"
    end
  end

  ls_result = `lpass ls '#{folder}'`
  if $CHILD_STATUS.exitstatus != 0
    raise Puppet::ParseError, "error: lpass ls '#{folder}': #{status}"
  end

  ls_result =~ %r{#{Regexp.escape(folder)}/#{Regexp.escape(name)} \[id: ([^\]]+)\]}
  id = Regexp.last_match(1)
  unless id
    raise Puppet::ParseError, "error: unable to find id for '#{folder}/#{name}' in :\n#{ls_result}"
  end

  show_result = `lpass show '#{id}'`
  if $CHILD_STATUS.exitstatus != 0
    raise Puppet::ParseError, "error: lpass show '#{folder}/#{name}' [id: #{id}]: #{status}"
  end

  # Parsing the output could use some cleaning up, but this works for now.
  # The output appears to have reasonably consistent structure.
  # The first line is the SHARE/GROUP\PATH/UNIQUENAME [id: nnnn]
  # Following lines are Field Name: ...
  # The Notes field seems to be last, which makes sense since it can be
  # multi-line. Once it starts, just read everything else into it.
  note = {}
  note_type = ''
  start_notes = false

  show_result.split("\n").each do |field|
    if field =~ /(.*) \[id: ([^\]]+)\]/
      # Ignore the note path and id
    elsif field =~ /^Note_type: (.*)/
      note_type = Regexp.last_match(1)
    elsif field =~ /^Notes: (.*)/
      note['notes'] = Regexp.last_match(1)
      start_notes = true
    elsif start_notes
      note['notes'] << "\n"
      note['notes'] << field
    else
      name, value = field.split(': ')
      note[name] = value
    end
  end

  # Normalize the note into the expected return values. We probably
  # need to spend some time thinking about this before anything
  # is implemented. The predefined types are easy to map. Custom
  # types seem useful in the UI, but the name doesn't come through
  # and I'm not sure how custom types are shared.
  #
  # If the notes field value starts with '---', assume it is YAML
  # and parse it, returning the result.
  #
  # Otherwise, just return the parsed note.
  case note_type
  when 'Database'
    content = {
      'username' => note['Username'],
      'password' => note['Password'],
      'sid' => note['SID'],
      'database' => note['Database'],
      'type' => note['Type']
    }
  when 'Server'
    content = {
      'username' => note['Username'],
      'password' => note['Password'],
      'hostname' => note['Hostname']
    }
  when 'SSH Key'
    content = {
      'public' => note['Public Key'],
      'private' => note['Private Key'],
      'passphrase' => note['Passphrase'],
      'format' => note['Format'],
      'hostname' => note['Hostname']
    }
  else
    if note['notes'] =~ /^---/
      begin
        content = YAML.load(note['notes'])
      rescue
        content = note
      end
    else
      content = note
    end
  end

  content
end
