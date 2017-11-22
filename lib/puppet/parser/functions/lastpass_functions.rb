LPASS_FIELD_SEP = '<==>'.freeze
EXECUTE_OPTIONS = {:failonfail => false, :combine => true}.freeze

def check_environment
  evaluate_env_file('/etc/profile.d/lpass.sh', 'LPASS_HOME')
  raise Puppet::ParseError, "Expected login file (#{ENV['LPASS_HOME']}/login}) not found" \
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
    key, value = line.sub(/^[\s\t]*export[\s\t]*/, '').split('=', 2)
    ENV[key] = value.chomp unless value.nil? || value.empty?
  end
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
  which_result = Puppet::Util.which('lpass')
  raise Puppet::ParseError, 'lpass command not found' if which_result.empty?
  version = Puppet::Util::Execution.execute(['lpass', '--version'], EXECUTE_OPTIONS).to_s
  raise Puppet::ParseError, "unexpected lpass version: #{version}" unless version =~ /v1.1.2$/
end

def login
  check_environment

  status = Puppet::Util::Execution.execute(['lpass', 'status'], EXECUTE_OPTIONS)

  return status.to_s if status.exitstatus.eql?(0)

  raise Puppet::ParseError, "error: lpass status: #{status.to_s}" unless status.to_s =~ /^Not logged in/
  status = Puppet::Util::Execution.execute(['lpasslogin'], EXECUTE_OPTIONS)
  raise Puppet::ParseError, "error: lpass login: #{status.to_s}" unless status.exitstatus.eql?(0)
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
  status = Puppet::Util::Execution.execute(['lpass', 'ls', "--sync=#{sync_type}", folder], EXECUTE_OPTIONS)

  raise Puppet::ParseError, "error: lpass ls '#{folder}': #{status.to_s}" unless status.exitstatus.eql?(0)

  status.to_s =~ %r{#{Regexp.escape(folder)}/#{Regexp.escape(name)} \[id: ([^\]]+)\]}

  Regexp.last_match(1)
end

def item_exists(uniquename)
  status = Puppet::Util::Execution.execute(['lpass', 'show', "--sync=#{sync_type}", uniquename], EXECUTE_OPTIONS)

  return false if !status.exitstatus.eql?(0) && status.to_s =~ /Could not find specified account/
  return true if status.exitstatus.eql?(0) && status.to_s =~ /#{Regexp.escape(uniquename)} \[id: [^\]]+\]/

  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{status.to_s}"
end

# Items can be retreived by ID or UniqueName using the following functions.
# The get_ functions will throw an exception if the item is not found.
def get_item_by_id(id)
  status = Puppet::Util::Execution.execute(['lpass', 'show', "--sync=#{sync_type}",\
                                            id, "--format=%fn#{LPASS_FIELD_SEP}%fv"], EXECUTE_OPTIONS)

  raise Puppet::ParseError, "error: lpass show [id: #{id}]: #{status.to_s}" unless status.exitstatus.eql?(0)

  parse_item(status.to_s)
end

def get_item_by_uniquename(uniquename)
  status = Puppet::Util::Execution.execute(['lpass', 'show', "--sync=#{sync_type}",\
                                            uniquename, "--format=%fn#{LPASS_FIELD_SEP}%fv"], EXECUTE_OPTIONS)

  raise Puppet::ParseError, "error: lpass show [uniquename: #{uniquename}]: #{status.to_s}" \
    unless status.exitstatus.eql?(0)

  parse_item(status.to_s)
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
  content_file = Puppet::FileSystem::Uniquefile.new('puppet-lastpass')
  content_file.write(content)
  content_file.close
  status = Puppet::Util::Execution.execute(['lpass', 'add', "--sync=#{sync_type}", \
                                            '--non-interactive', \
                                            '--notes', "#{folder}/#{name}"], \
                                            EXECUTE_OPTIONS.merge({:stdinfile => content_file.path}))
  content_file.unlink

  raise Puppet::ParseError, "error: lpass add '#{folder}/#{name}': #{status.to_s}" \
    unless status.exitstatus.eql?(0)
end
