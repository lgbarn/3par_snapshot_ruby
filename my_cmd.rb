#!/usr/bin/ruby

#require "popen4"

@cmd = "ls"
def logger(args={})
  @cmd = args[:command]
  @logfile = args[:logfile]
  @output = `#{@cmd} 2>&1`
  @exitstatus = $?.exitstatus
  @log_output = "#{@cmd}\n\nreturn code #{@exitstatus}\n\n#{@output}\n--------------------------"
  File.open(@logfile, 'a+') { |file| file << @log_output }
  @exitstatus
end

logger(:command=>"#{@cmd}", :logfile=>"mylog")
#output = `ls test 2>&1`
#output = %x[ls]
#p $?.pid
#p $?.exitstatus
#p output

#puts output.to_i
#
#status = POpen4::popen4(cmd)
#
#p status.methods
