require "mac_dnc/version"
require "fileutils"
require "json"
require 'serialport'

## Monitor is 16 characters tall
## Monitor is 64 characters wide


class MacDNC

	DC1_TAPE_READER_ON  = 17
	DC3_TAPE_READER_OFF	= 19

	attr_accessor :port, :baud, :data_bits, :stop_bits, :parity, :serialport

  def initialize
  	@desktop_path = File.expand_path("~/Desktop")
  	@nc_file_path = File.join(@desktop_path, "MacDNC Files")
  	@config_file  = File.join(@nc_file_path, "mac_dnc_config.txt")
  end

  def setup
  	FileUtils.mkdir_p(@nc_file_path)

  	File.open(@config_file, "w+") do |file|
  		comments =  """
  			// This is a comment
  			// and some more comments...
  		""".split("\n").map {|x| x.strip }.join("\n")

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

  	`read -p "" ; open #{@config_file.gsub(' ', '\ ')}`
  end

  def load_config
  	File.open(@config_file) do |file|
  		config = JSON.load(file.read)

  		@port = config["serial_port"]
  		@baud = config["baud"]
  		@data_bits = config["data_bits"]
  		@stop_bits = config["stop_bits"]

  		case config["parity"]
  		when "even" then @parity = SerialPort::EVEN
  		when "odd"	then @parity = SerialPort::ODD
  		when "none" then @parity = SerialPort::NONE
  		end
  	end
  end

  def create_connection
  	@serialport = SerialPort.new(@port, @baud, @data_bits, @stop_bits, @parity)
		@serialport.flow_control = SerialPort::SOFT
  end

  def destroy_connection
  	@serialport.close
  end

  def nc_file_list
  	nc_files = Dir[File.join(@nc_file_path, "*.ngc")]
  	nc_files.sort!
  	nc_files.map! do |file|
  		{
	  		:file_path => file,
	  		:name => File.split(file)[1]
	  	}
  	end

  	nc_files
  end

  def file_path_for_number(file_number)
  	nc_file_list[file_number - 1][:file_path]
  end

  def listen

  end

  def pretty_file_listing
    list = nc_file_list.slice(0..19)

  	output = "\r"
  	output << "MacDNC Version: #{VERSION}, Running on: #{`echo $HOSTNAME`.strip}".ljust(64) + "\r"
    output << "\r"
    output << "  Program list:".ljust(64) + "\r"

    program_index = []

    20.times do |x|
      puts x % 10

      if list[x].nil?
        entry  = "  #{x + 1})".ljust(31)
      else
        name = list[x][:name].upcase.gsub(/[^A-Z0-9\-\_\.]/, "_")
        entry = "  #{x + 1}) #{name}".slice(0..28).ljust(31)
      end

      if program_index[x % 10].nil?
        program_index[x % 10] = entry
      else
        program_index[x % 10] << entry + "\r"
      end
    end

    output << program_index.join

    output_height = output.count("\r") - 1
    (14 - output_height).times {|x| output << "\r"}

    output << "Enter DNC,[PROGAM NUMBER]+ or TA,[PROGRAM NUMBER]+ to proceed".ljust(64) + "\r"

    output
  end

  def send_file_listing

  end

  def send_file(header, file_path)

  end

  def stream_data(data, dnc_mode = true)

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

	def log(string)

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
