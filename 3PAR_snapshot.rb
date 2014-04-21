#!/usr/local/rvm/rubies/ruby-2.1.1/bin/ruby

require 'optparse'
require './filesystem'
require './snapshots'
require './multipath'
require './threepar'
require './lvm'

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
    cmd_logger(:cmd => "/sbin/fuser -km #{fs}", :logfile => 'mylog')
    cmd_logger(:cmd => "/bin/umount #{fs}", :logfile => 'mylog')
    #puts "/sbin/fuser -km #{fs}"
    #puts "/bin/umount #{fs}"
  end

  # vgchange and remove volumegroups
  snap.pkg_vgs.each do |vg|
    cmd_logger(:cmd => "/sbin/vgchange -a n #{vg}", :logfile => 'mylog')
    cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')
    cmd_logger(:cmd => "/sbin/vgremove -ff #{vg}", :logfile => 'mylog')
    cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')
  end

  # ensure cleanup using dmsetup
  mp.pkg_dm_lvols.each do |lvol|
    cmd_logger(:cmd => "dmsetup remove #{lvol}", :logfile => 'mylog')
  end

  # Flush and remove devices from system
  snap.pkg_disks.each do |disk|
    `/sbin/multipath -l #{disk}`.each_line do |line|
      if /(?<scsi_device>\d+:\d+:\d+:\d+)\s+(?<blockdev>\w+)\s+/ =~ line
        cmd_logger(:cmd => "blockdev --flushbufs /dev/#{blockdev}", :logfile => 'mylog')
        cmd_logger(:cmd => "sleep 2\n", :logfile => 'mylog')
        cmd_logger(:cmd => "echo 1 > /sys/class/scsi_device/#{scsi_device}/device/delete", :logfile => 'mylog')
        cmd_logger(:cmd => "sleep 2\n", :logfile => 'mylog')
      end
    end
    cmd_logger(:cmd => "/sbin/multipath -f #{disk}", :logfile => 'mylog')
    cmd_logger(:cmd => "sleep 2\n", :logfile => 'mylog')
  end

  # remove 3par vlun from server
  snap.pkg_disks.each do |disk|
    server = `hostname -s`
    @lun_id = array.get_lun_id(disk)
    cmd_logger(:cmd => "cli removevlun -f  #{disk} #{@lun_id} #{server}", :logfile => 'mylog')
    cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')
  end

  # remove all snapshots related to current job
  #@removevv_list = snap.ro_rw_pairs.join(' ').gsub(/:/, ' ')
  @removevv_list = snap.rw_snap_disks.join(' ').gsub(/:/, ' ') ### Test lgb ###
  cmd_logger(:cmd => "cli removevv -f -snaponly -cascade #{@removevv_list}", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')

end

cmd_logger(:cmd => "rescan-scsi-bus.sh -l\n", :logfile => 'mylog')
cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
cmd_logger(:cmd => "multipath -F\n", :logfile => 'mylog')
cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
cmd_logger(:cmd => "multipathd -r\n", :logfile => 'mylog')
cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
cmd_logger(:cmd => "multipath -F\n", :logfile => 'mylog')
cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
cmd_logger(:cmd => "multipath -v2\n", :logfile => 'mylog')
cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')


if options[:enable]
  puts 'enabled '

  # create read-only snapshots
  @ro_snapshot_list = snap.src_ro_pairs.join(' ')
  cmd_logger(:cmd => "cli creategroupsv -ro #{@ro_snapshot_list}", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')

  # create read-write snapshots
  @rw_snapshot_list = snap.ro_rw_pairs.join(' ')
  cmd_logger(:cmd => "cli creategroupsv #{@rw_snapshot_list}", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')

#  # create read-write snapshots
#  @rw_snapshot_list = snap.src_rw_pairs.join(' ')
#  cmd_logger(:cmd => "cli creategroupsv #{@rw_snapshot_list}", :logfile => 'mylog')
#  cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')

  # set wwid and create vlun to server
  snap.pkg_disks.each do |disk|
    server = `hostname -s`
    @wwid = mp.get_3par_wwid(disk)
    cmd_logger(:cmd => "cli setvv -wwn #{@wwid} #{disk}", :logfile => 'mylog')
    cmd_logger(:cmd => "cli createvlun #{disk} auto #{server}", :logfile => 'mylog')
    cmd_logger(:cmd => "sleep 5\n", :logfile => 'mylog')
  end

  # set filter in /etc/lvm/lvm.conf and import vgs
  #lvm.set_filter(filter: mp.get_snap_filter(snap.pkg_disks))
  lvm.set_filter(filter: mp.get_filter, file: '/etc/lvm/lvm.conf')

###########
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
  cmd_logger(:cmd => "rescan-scsi-bus.sh -l\n", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
  cmd_logger(:cmd => "multipath -F\n", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
  cmd_logger(:cmd => "multipathd -r\n", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
  cmd_logger(:cmd => "multipath -F\n", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
  cmd_logger(:cmd => "multipath -v2\n", :logfile => 'mylog')
  cmd_logger(:cmd => "sleep 15\n", :logfile => 'mylog')
###########
  cmd_logger(:cmd => "mkdir /tmp/lvmtemp\n", :logfile => 'mylog')
  cmd_logger(:cmd => "cp -f /etc/lvm/lvm.conf /tmp/lvmtemp/\n", :logfile => 'mylog')
  ENV['LVM_SYSTEM_DIR']='/tmp/lvmtemp/'
  lvm.set_filter(filter: mp.get_snap_filter(snap.pkg_disks), file: '/tmp/lvmtemp/lvm.conf')
  @vg_map = {}
  snap.pkg_vgs.each do |vg|
    @clone_disks = []
    snap.pkg_disks.each do |disk|
      if /_#{vg}_/ =~ disk
        @clone_disks << "/dev/mapper/#{disk}"
      end
    end
    cmd_logger(:cmd => "vgimportclone --basevgname #{vg} #{@clone_disks.join(" ")}", :logfile => 'mylog')
  end

  # set final filter
  ENV['LVM_SYSTEM_DIR']=nil
  lvm.set_filter(filter: mp.get_filter, file: '/etc/lvm/lvm.conf')

  # perform vgchange and backup
  snap.pkg_vgs.each do |vg|
    cmd_logger(:cmd => "vgchange -a y #{vg}", :logfile => 'mylog')
    cmd_logger(:cmd => "vgcfgbackup #{vg}", :logfile => 'mylog')
  end

  # mount filesystems
  fstab.mounts.each do |mount|
    cmd_logger(:cmd => "mount #{mount}", :logfile => 'mylog')
  end

end
