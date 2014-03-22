#!/usr/local/rvm/rubies/ruby-2.1.1/bin/ruby

require 'optparse'
require './filesystem'
require './snapshots'
require './multipath'
require './threepar'
require '/home/lgbarn/3par_snapshot_ruby/lvm'

# Read all options from command line
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: snapshot.rb [options]'

  opts.on('-e', '--enable', 'Enable snapshot') do |e|
    options[:enable] = e
  end
  opts.on('-d', '--disable', 'Disable snapshot') do |d|
    options[:disable] = d
  end
  options[:source] = ''
  opts.on('-s', '--source source', 'Source package') do |s|
    options[:source] = s
  end
  options[:package] = ''
  opts.on('-p', '--package destination', 'Destination Package') do |p|
    options[:package] = p
  end

end.parse!

# Check for requred options...should move into parse area
if options[:source] == ''
  puts 'need source'
  exit
end
if options[:package] == ''
  puts 'need package'
  exit
end

def cmd_logger(args = {})
  @cmd = args[:cmd]
  @logfile = args[:logfile]
  @output = `#{@cmd} 2>&1`
  @exitstatus = $?.exitstatus
  @log_output = "#{@cmd}\n\nreturn code #{@exitstatus}\n\n#{@output}\n"
  File.open(@logfile, 'a+') { |file| file << @log_output }
  @exitstatus
end

# Initialize all Classes
fstab = Filesystem.new(:package => options[:package])
snap = Snapshots.new(source: options[:source], package: options[:package])
array = Threepar.new
lvm = LVM.new
mp = Multipath.new(vgs: snap.pkg_vgs, disks: snap.pkg_disks)

if options[:disable]
  puts 'disabled '

  # Unmount filesystems
  fstab.mounted.each do |fs|
    #cmd_logger(:cmd => "/sbin/fuser -km #{fs}", :logfile => 'mylog')
    #cmd_logger(:cmd => "/bin/umount #{fs}", :logfile => 'mylog')
    puts "/sbin/fuser -km #{fs}"
    puts "/bin/umount #{fs}"
  end

  # vgchange and remove volumegroups
  snap.pkg_vgs.each do |vg|
    puts "/sbin/vgchange -a n #{vg}"
    puts "/sbin/vgremove -ff #{vg}"
  end

  # ensure cleanup using dmsetup
  mp.pkg_dm_lvols.each do |lvol|
    puts "dmsetup remove #{lvol}"
  end

  # Flush and remove devices from system
  snap.pkg_disks.each do |disk|
    `/sbin/multipath -l #{disk}`.each_line do |line|
      if /(?<scsi_device>\d+:\d+:\d+:\d+)\s+(?<blockdev>\w+)\s+/ =~ line
        puts "blockdev --flushbufs /dev/#{blockdev}"
        puts "echo 1 > /sys/class/scsi_device/#{scsi_device}/device/delete"
      end
    end
    puts "/sbin/multipath -f #{disk}"
  end

  # remove 3par vlun from server
  snap.pkg_disks.each do |disk|
    server = `hostname -s`
    @lund_id = array.get_lun_id(disk)
    puts "cli removevlun -f  #{disk} #{@lun_id} #{server}"
  end

  # remove all snapshots related to current job
  @removevv_list = snap.ro_rw_pairs.join(' ').gsub(/:/, ' ')
  puts "cli removevv -f -snaponly -cascade #{@removevv_list}"

  # create read-only snapshots
  @ro_snapshot_list = snap.src_ro_pairs.join(' ')
  puts "cli creategroupsv -ro #{@ro_snapshot_list}"
end

if options[:enable]
  puts 'enabled '

  # create read-write snapshots
  @rw_snapshot_list = snap.ro_rw_pairs.join(' ')
  puts "cli creategroupsv #{@rw_snapshot_list}"

  # set wwid and create vlun to server
  snap.pkg_disks.each do |disk|
    server = `hostname -s`
    @wwid = mp.get_3par_wwid(disk)
    puts "cli setvv -wwn #{@wwid} #{disk}"
    puts "cli createvlun #{disk} auto #{server}"
  end

  # set filter in /etc/lvm/lvm.conf and import vgs
  #lvm.set_filter(filter: mp.get_snap_filter(snap.pkg_disks))
  @vg_map = {}
  snap.pkg_vgs.each do |vg|
    @clone_disks = []
    snap.pkg_disks.each do |disk|
      if /_#{vg}_/ =~ disk
        @clone_disks << "/dev/mapper/#{disk}"
      end
    end
    puts "vgimportclone --basevgname #{vg} #{@clone_disks.join(" ")}"
  end

  # set final filter
  #lvm.set_filter(filter: mp.get_filter)

  # perform vgchange and backup
  snap.pkg_vgs.each do |vg|
    puts "vgchange -a y #{vg}"
    puts "vgcfgbackup #{vg}"
  end

  # mount filesystems
  fstab.mounts.each do |mount|
    #cmd_logger(:cmd => "mount #{mount}", :logfile => 'mylog')
    puts "mount #{mount}"
  end

end
