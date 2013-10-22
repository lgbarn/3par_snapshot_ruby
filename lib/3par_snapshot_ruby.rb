class LVM
  attr_accessor :fstab, :dmsetup, :src, :dst
  def initialize
    self.fstab = '/etc/fstab'
    self.dmsetup = "/sbin/dmsetup"
  end
  def src(source)
    self.src = source
  end
  def dst(destination)
    self.dst = destination
  end
  def src_mounts(source)
    File.open(self.fstab, "r") do |f|
      f.each do |line|
        if match = line.match(/(\/pkg\/#{source}\/u.+?)\s+/)
          (@src_mounts ||= []).push(match.captures)
        end
      end
    end
    @src_mounts 
  end
  def dst_mounts(destination)
    File.open(self.fstab, "r") do |f|
      f.each do |line|
        if match = line.match(/(\/pkg\/#{destination}\/u.+?)\s+/)
          (@dst_mounts ||= []).push(match.captures)
        end
      end
    end
    @dst_mounts 
  end
  def dst_vgs(destination)
    File.open(self.fstab, "r") do |f|
      f.each do |line|
        if match = line.match(/\/dev\/(.+)\/lvol.+?\s+\/pkg\/#{destination}\/u.+?\s+/)
          (@dst_vgs ||= []).push(match.captures)
        end
      end
    end
    @dst_vgs.uniq
  end
  def dm_dst_devices(dst_vgs)
    dst_vgs.each do |vg|
      dmsetup_out = %x(#{self.dmsetup} info)
      (@dm_dst_devices ||= []).push(dmsetup_out.scan(/Name:\s+(.+_#{vg}_.+)/))
    end
    @dm_dst_devices.flatten
  end
  def dm_dst_lvols(dst_vgs)
    dst_vgs.each do |vg|
      dmsetup_out = %x(#{self.dmsetup} info)
      (@dm_dst_lvols ||= []).push(dmsetup_out.scan(/Name:\s+(#{vg}-.+)/))
    end
    @dm_dst_lvols.flatten
  end
end
