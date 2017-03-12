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

  get_item_by_id(id)
end
