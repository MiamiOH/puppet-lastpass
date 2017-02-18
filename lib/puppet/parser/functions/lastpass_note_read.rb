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

  u = lookupvar('lastpass::username')

  r = `lpass login #{u}`

  puts r

  r2 = `lpass ls`

  puts r2

  r3 = `lpass show #{folder}/#{name}`

  puts r3

end
