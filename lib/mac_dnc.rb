require "mac_dnc/version"
require "fileutils"
require "json"
require 'serialport'

class MacDNC
  def self.setup
  	desktop_path = File.expand_path("~/Desktop")
  	nc_file_path = File.join(desktop_path, "MacDNC Files")
  	config_file  = File.join(nc_file_path, "mac_dnc_config.txt")

  	FileUtils.mkdir_p(nc_file_path)

  	File.open(config_file, "w+") do |file|
  		comments =  """
  			// This is a comment
  			// and some more comments...
  		""".split.map {|x| puts x.inspect ; x.strip }.join("\n")

  		file.write comments

  		file.write JSON.pretty_generate({
  			:serial_port => "/dev/cu.usbserial0",
  			:baud => 9600,
  			:data_bits => 7,
  			:stop_bits => 1,
  			:parity => "even"
  		})
  	end

  	puts ">> The config files and NC files folder have been created on your desktop, press enter to setup MacDNC..."

  	`read -p "" ; open #{config_file.gsub(' ', '\ ')}`
  end
end



class RubyDNC

	DC1_TAPE_READER_ON  = 17
	DC3_TAPE_READER_OFF	= 19

	def initialize(port = "/dev/cu.usbvirtuserial", baud = 9600, data_bits = 7, stop_bits = 1, parity = SerialPort::EVEN)
		@baud = baud
		@data_bits = data_bits
		@stop_bits = stop_bits
		@parity = parity
		@port = port

		@serialport = SerialPort.new(@port, @baud, @data_bits, @stop_bits, @parity)
		@serialport.flow_control = SerialPort::SOFT

		puts @serialport.get_modem_params
	end

	def send_file(file_path)
		lines = File.open(file_path).readlines
		lines = optimize_data(lines)

		wait_until_receive_tape_on

		lines.each do |line|
			wait_until_receive_tape_on if received_tape_off?

			puts line.inspect
			@serialport.write(line)
		end
	end

	def optimize_data(lines)
		lines = lines.map {|x| x.encode("US-ASCII")}			# Transcode to 7-bit ASCII
		lines = lines.map {|x| x.gsub(/^N\d*\.?\d*/, "")}	# Remove leading line numbers
		lines = lines.map {|x| x.gsub(/\(.*/, "")}				# Remove comments
		lines = lines.map {|x| x.strip + "\r"}						# Append a carriage return to each line
	end

	def received_tape_off?
		while @serialport.stat.size > 0
			return true if @serialport.get_byte == DC3_TAPE_READER_OFF
		end
		false
	end

	def wait_until_receive_tape_on
		loop do
			@serialport.eof?
			break if @serialport.getbyte == DC1_TAPE_READER_ON
		end
	end

	def receive
		while true do
			@serialport.eof?
			byte = @serialport.getbyte
			if byte > 32 && byte < 128
				print byte.chr
			else
				print byte
			end

		  #puts(@serialport.getbyte)
		end
	end
end

#dnc = RubyDNC.new()
#dnc.receive()
#dnc.send_file("/Users/aarongough/work/ruby_dnc/dnc_test.ngc")
