require_relative 'lastpass_functions'

# Retrieves from a LastPass secure note. Throws an exception if the item
# does not exist.
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

  get_item_by_uniquename("#{folder}/#{name}")
end
