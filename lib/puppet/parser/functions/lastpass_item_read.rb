require 'fileutils'
require 'yaml'
require 'English'
# require 'etc'

# Retrieves from a LastPass secure note
#
# Useful for having data that is managed via LastPass and shared with Puppet.
#
# Usage: lastpass_item_read(folder, name)
# Example: $db_config = lastpass_item_read('oracle/db', 'appuser')
Puppet::Parser::Functions.newfunction(:lastpass_item_read, :type => :rvalue) do |args|
  raise Puppet::ParseError, 'Usage: lastpass_item_read(folder, name)' unless args.size == 2

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
    raise Puppet::ParseError, "error: lpass status: #{status}" unless status == 'Not logged in.'
    login_result = `lpass login #{username}`
    raise Puppet::ParseError, "error: lpass login: #{login_result}" unless login_result =~ /^Success:/
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
  start_notes = false

  show_result.split("\n").each do |field|
    if field =~ /(.*) \[id: ([^\]]+)\]/
      # Ignore the note path and id
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

  note
end
