class Multipath
  attr_reader :package, :source, :vgs

  def initialize(args = {})
    @package = args[:package]
    @source = args[:source]
    @dmsetup = `/sbin/dmsetup ls`
    @p_vgs = args[:vgs]
    @p_disks = args[:disks]
    @default_filter = 'filter = [ "a|/dev/sda$|", "a|/dev/sda1$|", "a|/dev/sda2$|", "a|/dev/sda3$|", "a|/dev/mapper/.*|", "a|/dev/disk/by-id/dm-name.*|", "r|.*|" ]'
    @begin_filter = 'filter = [ "a|/dev/sda$|", "a|/dev/sda1$|", "a|/dev/sda2$|", "a|/dev/sda3$|"'
    @begin_snap_filter = 'filter = [ '
    @end_filter = '"r|.*|" ]'
  end

  def pkg_dm_lvols
    @pkg_dm_lvols = []
    @p_vgs.each do |vg|
      @dmsetup.each_line do |line|
        @pkg_dm_lvols << $1 if /(#{vg}-lvol.+?)\s+/ =~ line
      end
    end
    @pkg_dm_lvols
  end

  def pkg_dm_disks
    @pkg_dm_disks = []
    @p_disks.each do |disk|
      @dmsetup.each_line do |line|
        @pkg_dm_disks << dm_disk if /(?<dm_disk>#{disk})\s+/ =~ line
      end
    end
    @pkg_dm_disks
  end

  def parse_multipath_conf
    multipath_map = {}
    @multipathd_config = `multipathd -k'show config'`
    @multipathd_config.each_line do |line|
      @curr_wwid = $1 if /wwid\s+(\w+)/ =~ line
      if line =~ /alias\s+(\w+)/
        curr_alias = $1
        multipath_map[curr_alias] = @curr_wwid
      end
    end
    multipath_map
  end

  def get_3par_wwid(ali)
    multipath_map = self.parse_multipath_conf
    multipath_map[ali].gsub(/^./, "")
  end

  def get_host_wwid(ali)
    multipath_map = self.parse_multipath_conf
    multipath_map[ali]
  end

  def get_disks
    @disks = []
    @show_maps = `multipathd -k'show maps'`
    @show_maps.each_line do |line|
      if line =~ /(\w+)\s+dm-/
        @disks << $1
      end
    end
    @disks
  end

  def get_filter
    @filter = []
    @filter << @begin_filter
    self.get_disks.each do |disk|
      @mapper_disk = disk.gsub(/^/, '"a|/dev/mapper/').gsub(/$/, '|"')
      @filter.push << @mapper_disk
    end
    @filter << @end_filter
    @filter.join(", ")
  end

  def get_default_filter
    @default_filter
  end

  def get_snap_filter(disks)
    @snap_disks = disks
    @filter = []
    #@filter << @begin_snap_filter
    @snap_disks.each do |disk|
      @mapper_disk = disk.gsub(/^/, '"a|/dev/mapper/').gsub(/$/, '|"')
      @filter.push << @mapper_disk
    end
    @filter << @end_filter
    "#{@begin_snap_filter}#{@filter.join(", ")}"
  end

end

