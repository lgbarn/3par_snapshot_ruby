#!/usr/bin/ruby

class Device
  attr_accessor :multipath_cmd, :device_file
  def initialize(args = {})
    self.multipath_cmd = "/sbin/multipath"
  end
  def device(device_file)
    self.device_file = device_file
  end
  def run_mp_cmd()
    @cmd_output = %x(#{self.multipath_cmd} -l #{self.device_file})
    $?
  end
  def get_paths()
    @cmd_output.scan(/(\d+:\d+:\d+:\d+)\s+(\w+)\s+/)
  end
end

mp = Device.new
ARGV.each do |arg|
  puts "### removing device #{arg} ###"
  mp.device(arg)
  mp.run_mp_cmd
  mp.get_paths.each do |scsi_device, block_device|
    puts "blockdev --flushbufs /dev/#{block_device}"
    puts "echo 1 > /sys/class/scsi_device/#{scsi_device}/device/delete"
  end
  puts 
end
