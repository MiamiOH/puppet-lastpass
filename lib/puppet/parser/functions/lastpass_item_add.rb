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

  raise Puppet::ParseError, "error: existing item '#{folder}/#{name}'" if item_exists("#{folder}/#{name}")

  create_item(folder, name, content)

  # Fetch the newly created item. This both tests the creation and yields the result
  # in the expected format.
  get_item_by_uniquename("#{folder}/#{name}")
end
