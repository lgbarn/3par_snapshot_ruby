class LVM
  def set_filter(args={})
    @filter = args[:filter]
    filename = "/home/lgbarn/3par_snapshot_ruby/lvm.conf"
    f = File.open(filename, 'r')
    @newfile = []
    f.each_line do |line|
      clean_line = line.gsub(/#.*/, "")
      if clean_line =~ /filter.*=/
        @newfile << line.gsub(/filter.*=.*$/, @filter)
      else
        @newfile << line
      end
    end
    f = File.open(filename, 'w') { |file| file << @newfile }
  end
end


