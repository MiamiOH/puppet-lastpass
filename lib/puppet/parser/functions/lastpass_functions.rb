require 'open3'

LPASS_FIELD_SEP = '<==>'.freeze
LPASS_MINIMUM_VERSION = '1.1.2'.freeze

def check_environment
  evaluate_env_file('/etc/profile.d/lpass.sh', 'LPASS_HOME')
  raise Puppet::ParseError, "Expected login file (#{ENV['LPASS_HOME']}/login) not found" \
    unless File.file?("#{ENV['LPASS_HOME']}/login")
  import_env_file("#{ENV['LPASS_HOME']}/env")
  check_lpass
end

# assumes the following format
#  export NAME1=value1
#  export NAME2=value2
# or
#  NAME1=value1
#  NAME2=value2
#
# NOTE: Does not interpret values with other shell variables
def import_env_file(path)
  return unless File.file?(path)
  File.readlines(path).each do |line|
    next if line.start_with?('#') || line.strip.empty?
    line_to_env(line)
  end
end

def line_to_env(line)
  key, value = line.sub(/^[\s\t]*export[\s\t]*/, '').split('=', 2)
  return unless key.start_with?('LPASS_') # we don't want things like http_proxy
  ENV[key] = value.chomp unless value.nil? || value.empty?
end

# Actually evaluates a bash shell script for exported env vars
# You must list the vars you are looking for
def evaluate_env_file(path, vars)
  return unless File.file?(path)
  Array(vars).each do |var|
    next if ENV[var]
    value = `source #{path} 2> /dev/null && echo $#{var}`.chomp
    ENV[var] = value unless value.nil? || value.empty?
  end
end

def check_lpass
  which_result, _error, _status = Open3.capture3('which', 'lpass')
  raise Puppet::ParseError, 'lpass command not found' if which_result.empty?
  version_string, _error, _status = Open3.capture3('lpass', '--version')
  name, version = version_string.match(/^(.*) v(.*)$/).captures
  raise Puppet::ParseError, "unexpected #{name} version: #{version}" \
    unless call_function('versioncmp', [version, LPASS_MINIMUM_VERSION]) >= 0
end

def login
  check_environment

  lpass_status, error, status = Open3.capture3('lpass', 'status')

  return lpass_status if status.success?

  raise Puppet::ParseError, "error: lpass status: #{error}" unless lpass_status =~ /^Not logged in/
  _login_result, error, status = Open3.capture3('lpasslogin')
  raise Puppet::ParseError, "error: lpass login: #{error}" unless status.success?
end

def sync_type
  sync_type = ENV['LPASS_SYNC_TYPE'] || 'auto'
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

# Items can be retreived by ID or UniqueName using the following functions.
# The get_ functions will throw an exception if the item is not found.
def get_item_by_id(id)
  show_result, error, status = Open3.capture3('lpass', 'show', "--sync=#{sync_type}",\
                                              id, "--format=%fn#{LPASS_FIELD_SEP}%fv")

  raise Puppet::ParseError, "error: lpass show [id: #{id}]: #{error}" unless status.success?

  parse_item(show_result)
end

def get_item_by_uniquename(uniquename)
  show_result, error, status = Open3.capture3('lpass', 'show', "--sync=#{sync_type}",\
                                              uniquename, "--format=%fn#{LPASS_FIELD_SEP}%fv")

  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{error}" \
    unless status.success?
  # lpass returns exit status of success, even though we consider it to be an error when
  # multiple matches are found. Our code does not handle that very well and I'm not sure
  # what we could actually do about it, other than explode with a good message.
  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: Multiple matches found" \
    if show_result =~ /Multiple matches found/

  parse_item(show_result)
end

# The output appears to have reasonably consistent structure.
# The first line is the SHARE/GROUP\PATH/UNIQUENAME [id: nnnn]
# The following lines will contain key/value pairs separated by
# our defined field separator. The values may be multi-line, so
# subsequent lines are appended to the key currently being read.
def parse_item(item)
  note = {}
  field = nil

  item.split("\n").each do |line|
    # Ignore the path and id line
    next if line =~ /(.*) \[id: ([^\]]+)\]/

    if line =~ /#{LPASS_FIELD_SEP}/
      field, value = line.split(LPASS_FIELD_SEP)
      note[field] = value
    elsif field && note[field]
      note[field] << "\n#{line}"
    else
      raise Puppet::ParseError, "error: lpass parse_item [item: #{item}]: no field seperator"
    end
  end

  note
end

def create_item(folder, name, content)
  _add_result, error, status = Open3.capture3('lpass', 'add', "--sync=#{sync_type}", \
                                              '--non-interactive', \
                                              '--notes', "#{folder}/#{name}", \
                                              :stdin_data => content)

  raise Puppet::ParseError, "error: lpass add '#{folder}/#{name}': #{error}" \
    unless status.success?
end
