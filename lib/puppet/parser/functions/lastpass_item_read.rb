require 'fileutils'
require 'yaml'
require 'English'

require_relative 'lastpass_functions'

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

  login

  id = item_id(folder, name)
  raise Puppet::ParseError, "error: unable to find id for '#{folder}/#{name}'" unless id

  show_result = `lpass show --sync=#{sync_type} '#{id}'`
  raise Puppet::ParseError, "error: lpass show '#{folder}/#{name}' [id: #{id}]: #{show_result}" \
    unless $CHILD_STATUS.exitstatus.zero?

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
      note['Notes'] = Regexp.last_match(1)
      start_notes = true
    elsif start_notes
      note['Notes'] << "\n"
      note['Notes'] << field
    else
      name, value = field.split(': ')
      note[name] = value
    end
  end

  note
end
