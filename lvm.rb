class LVM
  def set_filter(args={})
    @filter = args[:filter]
    filename = "/home/lgbarn/3par_snapshot_ruby/lvm.conf"
    f = File.open(filename, 'r')
    @newfile = []
    f.each_line do |line|
      clean_line = line.gsub(/#.*$/, '')
      if clean_line =~ /filter\s+=/
        line.gsub!(/filter.*$/, @filter)
      end
      @newfile << line.chomp
    end
    File.open(filename, 'w') { |f| f.write(@newfile.join("\n")) }
  end
end


