require "mac_dnc/version"
require "fileutils"
require "json"
require 'serialport'

# Fadal CNC88 monitor is 16 characters tall
# Fadal CNC88 monitor is 64 characters wide


class MacDNC

	DC1_TAPE_READER_ON  = 17
	DC3_TAPE_READER_OFF	= 19

	NEWLINE = 64.chr

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
  			// This is the config file for MacDNC
  			// change the settings to suit your setup
  			// but make sure to leave the file structure
  			// as it is.
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
    @serialport.flush_output
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
  	nc_file_list[file_number.to_i - 1][:file_path]
  end

  def listen
    loop do
      begin
        @serialport.read unless @serialport.stat.size == 0 # clear input buffer
        input = ""
        loop do
          @serialport.eof?
          byte = @serialport.getbyte
          puts byte
          break if byte == 43
          input << byte.chr
        end
  
        puts input
  
        input = input.gsub("ENTER NEXT COMMAND", "").strip.split("\r").last
        input_parts = input.split(",")
        command = input_parts[0].strip
        parameter = input_parts[1]

        puts "COMMAND: " + command.inspect
        puts "PARAMETER: " + parameter.inspect
  
        case command
        when "DIR"
          send_file_listing()
        when "TA"
          path = file_path_for_number(parameter)
          send_file(:tape, path)
        when "DNC"
          path = file_path_for_number(parameter)
          send_file(:dnc, path)
        else
          puts "UNRECOGNIZED COMMAND"
          stream_data(NEWLINE + "UNRECOGNIZED COMMAND" + NEWLINE + "BYE\r")
        end
      rescue Interrupt
        @serialport.close
        raise Interrupt
      end
    end
  end

  def pretty_file_listing
    list = nc_file_list.slice(0..17)

  	output = ""
  	output << NEWLINE + "MacDNC Version: #{VERSION}, Running on: #{`echo $HOSTNAME`.strip}".ljust(62) + NEWLINE
    output << "".ljust(62) + NEWLINE
    output << "  Program list:".ljust(62) + NEWLINE

    program_index = []

    18.times do |x|
      if list[x].nil?
        entry  = "  #{x + 1})".ljust(31)
      else
        name = list[x][:name].upcase.gsub(/[^A-Z0-9\-\_\.]/, "_")
        entry = "  #{x + 1}) #{name}".slice(0..28).ljust(31)
      end

      if program_index[x % 9].nil?
        program_index[x % 9] = entry
      else
        program_index[x % 9] << entry.ljust(31) + NEWLINE
      end
    end

    output << program_index.join
    output << "".ljust(62) + NEWLINE
    output << "Enter DNC,[PROGAM NUMBER]+ or TA,[PROGRAM NUMBER]+".ljust(62) + NEWLINE
    output << "BYE\r"

    output
  end

  def send_file_listing
    stream_data(pretty_file_listing.encode("US-ASCII"))
  end

  def send_file(mode = :tape, file_path)
    data = File.open(file_path).read
    data = data.split(/\r/)
    data = encode_data(data)

    case mode
    when :tape
      stream_data(NEWLINE + "TA,1\r")
    when :dnc
      data = optimize_data_for_dnc(data)
      stream_data(NEWLINE + "DNC\r")
    end

    wait_until_receive_tape_on
    stream_data(data)
  end

  def stream_data(data)
    if data.is_a?(String)
      puts data
      @serialport.write(data)
    elsif data.is_a?(Array)
      data.each do |line|
        puts line
        @serialport.write(line)
      end
    end
  end

  def encode_data(data)
    data = data.map {|x| x.encode("US-ASCII")}      # Transcode to 7-bit ASCII
    data = data.map {|x| x.strip + "\r"}            # Append a carriage return to each line
  end

  def optimize_data_for_dnc(data)
    data = data.map {|x| x.gsub(/^N\d*\.?\d*/, "")} # Remove leading line numbers
    data = data.map {|x| x.gsub(/^O\d*\.?\d*/, "")} # Remove program numbers
    data = data.map {|x| x.gsub(/\(.*/, "")}        # Remove comments
  end

  def received_tape_off?
		while @serialport.stat.size > 0
			return true if @serialport.get_byte == DC3_TAPE_READER_OFF
		end
		false
	end

	def wait_until_receive_tape_on
    @serialport.read unless @serialport.stat.size == 0
		loop do
			@serialport.eof?
			break if @serialport.getbyte == DC1_TAPE_READER_ON
		end
	end

	def log(string)
    puts string
	end
end
