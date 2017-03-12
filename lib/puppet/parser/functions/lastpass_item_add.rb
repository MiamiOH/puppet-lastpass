require 'fileutils'
require 'yaml'
require 'English'

require_relative 'lastpass_functions'

# Adds a LastPass generic secure note
#
# Allows puppet to add a LastPass secure note.
#
# Usage: lastpass_item_add(folder, name, content)
# Example: $db_config = lastpass_item_add('oracle/db', 'appuser', 'content goes here')
Puppet::Parser::Functions.newfunction(:lastpass_item_add, :type => :rvalue) do |args|
  raise Puppet::ParseError, 'Usage: lastpass_item_add(folder, name, content)' unless args.size == 3

  folder = args[0]
  raise Puppet::ParseError, 'Must provide folder' if folder.empty?

  name = args[1]
  raise Puppet::ParseError, 'Must provide data name' if name.empty?

  content = args[2]
  # Content can be empty

  login

  id = item_id(folder, name)
  raise Puppet::ParseError, "error: item '#{folder}/#{name}' found with id #{id}" if id

  options = "--sync=#{sync_type} --non-interactive --notes"
  add_result = `echo "#{content}" | lpass add #{options} '#{folder}/#{name}'`
  raise Puppet::ParseError, "error: lpass add '#{folder}/#{name}': #{add_result}" \
    unless $CHILD_STATUS.exitstatus.zero?

  # Fetch the newly created item. This both tests the creation and yields the result
  # in the expected format. Getting by id doesn't work for newly created items.
  get_item_by_uniquename("#{folder}/#{name}")
end
