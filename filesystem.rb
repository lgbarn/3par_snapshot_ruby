class Filesystem
  attr_reader :package

  def initialize(args = {})
    @package = args[:package]
  end

  def mounts
    mounts = []
    f = File.open('/etc/fstab', 'r')
    f.each_line do |line|
      match = %r"\s+(?<mount>/pkg/#{@package}/u.+?)\s+".match(line)
      mounts << match[:mount] if match 
    end
    mounts
  end

  def mounted
    mounts = []
    f = File.open('/proc/mounts', 'r')
    f.each_line do |line|
      match = %r"\s+(?<mount>/pkg/#{@package}/u.+?)\s+".match(line)
      mounts << match[:mount] if match 
    end
    mounts
  end
end
