class Threepar
  def parse_lun_id
    @lun_id_map = {}
    @host = `hostname -s`
    @showvlun = `cli showvlun -t -host #{@host}`
    @showvlun.each_line do |line|
      if line =~ /\s+(\d+)\s+(\w+).*\s+host/
        @vlunid = $1
        @vlun_name = $2
        @lun_id_map[@vlun_name] = @vlunid
      end
    end
  end

  def get_lun_id(vlun)
    self.parse_lun_id
    @lun_id_map[vlun]
  end
end

