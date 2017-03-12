require 'fileutils'
require 'English'
require 'pathname'

def check_environment
  user_path = Pathname.new("#{ENV['LPASS_HOME']}/user")
  raise Puppet::ParseError, "Expected user file (#{ENV['LPASS_HOME']}/user}) not found" \
    unless user_path.exist?

  pw_path = Pathname.new("#{ENV['LPASS_HOME']}/pw")
  raise Puppet::ParseError, "Expected password file (#{ENV['LPASS_HOME']}/pw}) not found" \
    unless pw_path.exist?

  check_lpass
end

def check_lpass
  cmd = `which lpass`
  raise Puppet::ParseError, 'lpass command not found' if cmd.empty?
  version = `lpass --version`.strip
  raise Puppet::ParseError, "unexpected lpass version: #{version}" unless version =~ /v1.1.2$/
end

def login
  check_environment

  status = `lpass status`.strip

  return status if $CHILD_STATUS.exitstatus.zero?

  raise Puppet::ParseError, "error: lpass status: #{status}" unless status == 'Not logged in.'
  login_result = `lpasslogin`
  raise Puppet::ParseError, "error: lpass login: #{login_result}" unless login_result =~ /^Success:/
end

def sync_type
  sync_type = ENV['LPASS_USER_SYNC_TYPE'] || 'auto'
  raise Puppet::ParseError, "Invalid sync type #{sync_type} (now, auto, no)" \
    unless sync_type =~ /^(now|auto|no)$/

  sync_type
end

def item_id(folder, name)
  ls_result = `lpass ls --sync=#{sync_type} '#{folder}'`
  raise Puppet::ParseError, "error: lpass ls '#{folder}': #{ls_result}" unless $CHILD_STATUS.exitstatus.zero?

  ls_result =~ %r{#{Regexp.escape(folder)}/#{Regexp.escape(name)} \[id: ([^\]]+)\]}

  Regexp.last_match(1)
end

def get_item_by_id(id)
  show_result = `lpass show --sync=#{sync_type} '#{id}'`
  raise Puppet::ParseError, "error: lpass show [id: #{id}]: #{show_result}" \
    unless $CHILD_STATUS.exitstatus.zero?

  parse_item(show_result)
end

def get_item_by_uniquename(uniquename)
  show_result = `lpass show --sync=#{sync_type} '#{uniquename}'`
  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{show_result}" \
    unless $CHILD_STATUS.exitstatus.zero?

  parse_item(show_result)
end

def parse_item(item)
  # Parsing the output could use some cleaning up, but this works for now.
  # The output appears to have reasonably consistent structure.
  # The first line is the SHARE/GROUP\PATH/UNIQUENAME [id: nnnn]
  # Following lines are Field Name: ...
  # The Notes field seems to be last, which makes sense since it can be
  # multi-line. Once it starts, just read everything else into it.
  note = {}
  start_notes = false

  item.split("\n").each do |field|
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