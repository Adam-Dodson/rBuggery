require 'pp'
require 'buggery'

debug_client=Buggery::Debugger.new

exception_callback=lambda {|args|
  # FFI::Struct, with some extra sugar in the class
  exr=Buggery::Structs::ExceptionRecord64.new args[:exception_record]
  unless exr[:record].null?
    puts "debug: #{exr[:record][:code]}"
  end
  if args[:first_chance].zero?
    # We can either use the ExceptionRecord64 directly
    puts "#{"%8.8x" % exr[:code]} - Second chance"
    @fatal_exception=true
    # Or any native windbg commands or extensions
    puts "\n#{debug_client.execute '!exploitable'}\n"
    puts debug_client.execute "ub @$ip"
    puts debug_client.execute "u @$ip"
    puts debug_client.execute "r"
    return 1
  else
    puts "0x#{exr.code} @ 0x#{exr.address} - First chance"
    # Or sugar for the windbg '.exr' command
    pp debug_client.exception_record
  end
  puts "--------------"
  0 # DEBUG_STATUS_NO_CHANGE
}

debug_client.event_callbacks.add( :exception=>exception_callback )

debug_client.create_process(
  "C:\\Program Files\\Microsoft Office\\Office15\\WINWORD.EXE #{ARGV[0]}"
)
debug_client.execute "!load winext\\msec.dll"
loop do
  debug_client.wait_for_event 10
  break if @fatal_exception
  break unless debug_client.has_target?
end
