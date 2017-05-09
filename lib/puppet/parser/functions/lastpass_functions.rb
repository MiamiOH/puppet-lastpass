require 'open3'

LPASS_FIELD_SEP = '<==>'.freeze

def check_environment
  raise Puppet::ParseError, "Expected login file (#{ENV['LPASS_HOME']}/login}) not found" \
    unless File.file?("#{ENV['LPASS_HOME']}/login")

  if File.file?("#{ENV['LPASS_HOME']}/env")
    # assumes the following format
    #  NAME1=value1
    #  NAME2=value2
    File.readlines("#{ENV['LPASS_HOME']}/env").each do |line|
      key, value = line.split '='
      ENV[key] = value
    end
  end

  check_lpass
end

def check_lpass
  which_result, _error, _status = Open3.capture3('which', 'lpass')
  raise Puppet::ParseError, 'lpass command not found' if which_result.empty?
  version, _error, _status = Open3.capture3('lpass', '--version')
  raise Puppet::ParseError, "unexpected lpass version: #{version}" unless version =~ /v1.1.2$/
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
    else
      note[field] << "\n#{line}"
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
