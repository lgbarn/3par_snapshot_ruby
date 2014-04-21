class LVM
  def set_filter(args={})
    @filter = args[:filter]
    @file = args[:file]
    f = File.open(@file, 'r')
    @newfile = []
    f.each_line do |line|
      clean_line = line.gsub(/#.*$/, '')
      if clean_line =~ /filter\s+=/
        line.gsub!(/filter.*$/, @filter)
      end
      @newfile << line.chomp
    end
    File.open(@file, 'w') { |f| f.write(@newfile.join("\n")) }
  end
end


