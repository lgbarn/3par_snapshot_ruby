class Snapshots
  attr_reader :package, :source

  def initialize(args = {})
    @package = args[:package]
    @source = args[:source]
  end

  def pkg_vgs
    vgs = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      vgs << $1.chomp if /disk:.*:#{@package}_(vg.+)_/ =~ line
    end
    vgs.uniq
  end

  def pkg_disks
    disks = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      disks << $1.chomp if /disk:#{@source}_vg.+_.*:(#{@package}_vg.+_.*)/ =~ line
    end
    disks.uniq
  end

  def src_ro_pairs
    disks = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      if /disk:(#{@source}_vg.+_.*):(#{@package}_vg.+_.*)/ =~ line
        curr_ro_pair = "#{$1.chomp}:#{$2.chomp}.ro"
        disks << curr_ro_pair
      end
    end
    disks.uniq
  end

  def ro_rw_pairs
    disks = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      if /disk:(#{@source}_vg.+_.*):(#{@package}_vg.+_.*)/ =~ line
        curr_ro_pair = "#{$2.chomp}.ro:#{$2.chomp}"
        disks << curr_ro_pair
      end
    end
    disks.uniq
  end

  def src_rw_pairs
    disks = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      if /disk:(#{@source}_vg.+_.*):(#{@package}_vg.+_.*)/ =~ line
        curr_ro_pair = "#{$1.chomp}:#{$2.chomp}"
        disks << curr_ro_pair
      end
    end
    disks.uniq
  end

  def rw_snap_disks
    disks = []
    f = File.open('/etc/snapshots.conf', 'r')
    f.each_line do |line|
      if /disk:(#{@source}_vg.+_.*):(#{@package}_vg.+_.*)/ =~ line
        curr_rw_pair = "#{$2.chomp}"
        disks << curr_rw_pair
      end
    end
    disks.uniq
  end
end
