require 'fileutils'
require 'English'
require 'pathname'
require 'open3'

LPASS_FIELD_SEP = '<==>'.freeze

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

# This is not very efficient. The ls command only lists the entire contents
# of a folder. Use of this function has been removed, it is only here for
# reference. We may want to add a "find" function which can use the basic
# regex feature (lpass show -G pattern) to find and return IDs.
def item_id(folder, name)
  ls_result, error, status = Open3.capture3('lpass', 'ls', "--sync=#{sync_type}", folder)

  raise Puppet::ParseError, "error: lpass ls '#{folder}': #{error}" unless status.success?

  ls_result =~ %r{#{Regexp.escape(folder)}/#{Regexp.escape(name)} \[id: ([^\]]+)\]}

  Regexp.last_match(1)
end

def item_exists(uniquename)
  show_result, error, status = Open3.capture3('lpass', 'show', "--sync=#{sync_type}", uniquename)

  return false if !status.success? && error =~ /Could not find specified account/
  return true if status.success? && show_result =~ /#{Regexp.escape(uniquename)} \[id: [^\]]+\]/

  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{error}"
end

def get_item_by_id(id)
  show_result, error, status = Open3.capture3('lpass', 'show', "--sync=#{sync_type}",\
                                              id, "--format='%fn#{LPASS_FIELD_SEP}%fv'")

  raise Puppet::ParseError, "error: lpass show [id: #{id}]: #{error}" unless status.success?

  parse_item(show_result)
end

def get_item_by_uniquename(uniquename)
  show_result, error, status = Open3.capture3('lpass', 'show', "--sync=#{sync_type}",\
                                              uniquename, "--format='%fn#{LPASS_FIELD_SEP}%fv'")

  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{error}" \
    unless status.success?

  parse_item(show_result)
end

# Parsing the output could use some cleaning up, but this works for now.
# The output appears to have reasonably consistent structure.
# The first line is the SHARE/GROUP\PATH/UNIQUENAME [id: nnnn]
# Following lines are Field Name: ...
# The Notes field seems to be last, which makes sense since it can be
# multi-line. Once it starts, just read everything else into it.
def parse_item(item)
  note = {}
  field = nil

  item.split("\n").each do |line|
    # Ignore the path and id line
    next if line =~ /(.*) \[id: ([^\]]+)\]/

    if line =~ /#{LPASS_FIELD_SEP}/
      field, value = line.split(LPASS_FIELD_SEP)
      note[field] = value
    else
      note[field] << "\n#{line}"
    end
  end

  note
end

def create_item(folder, name, content)
  add_result, error, status = Open3.capture3('lpass', 'add', "--sync=#{sync_type}", \
                                             '--non-interactive', \
                                             '--notes', "#{folder}/#{name}", \
                                             :stdin_data => content)
  puts add_result
  raise Puppet::ParseError, "error: lpass add '#{folder}/#{name}': #{error}" \
    unless status.success?
end
