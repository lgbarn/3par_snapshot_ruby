#!/usr/bin/ruby

File.open("/etc/fstab", "r") do |f|
  f.each do |line|
    if match = line.match(/\/dev\/(.+)\/lvol.+?\s+\/pkg\/newtest\/u.+\s+/)
      (@dst_vgs ||= []).push(match.captures)
    end
  end
  puts @dst_vgs.uniq.inspect
end

