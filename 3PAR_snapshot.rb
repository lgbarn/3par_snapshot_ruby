#!/usr/bin/ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: snapshot.rb [options]"

  opts.on("-e", "--enable", "Enable snapshot") do |e|
    options[:enable] = e
  end
  opts.on("-d", "--disable", "Disable snapshot") do |d|
    options[:disable] = d
  end
  options[:source] = ""
  opts.on("-s", "--source source", "Source package") do |s|
    options[:source] = s
  end
  options[:package] = ""
  opts.on("-p", "--package destination", "Destination Package") do |p|
    options[:package] = p
  end

end.parse!

if options[:enable ]
  puts "enabled "
end
if options[:disable]
  puts "disabled "
end
if options[:source] == ""
  puts "need source"
  exit
end
if options[:package] == ""
  puts "need package"
  exit
end

class Filesystem
  #attr_reader pkg
  def mounts(pkg)
    package = pkg
    f = File.open("/home/lgbarn/3par_snapshot_ruby/fstab", 'r')
    f.each_line do |line|
      if line =~ %r"\s+(/pkg/#{package}/u.+?)\s+?"
        puts $1
      end
    end
  end
end

fstab = Filesystem.new
fstab.mounts(options[:package])
