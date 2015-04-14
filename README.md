# MacDNC

A simple to use DNC server optimized for Fadal machining centers.

DNC stands for 'direct numeric control' and refers to the ability to stream g-code to a CNC machine tool like a Vertical Machining Center. This enables the tool to execute lengthy programs that would not otherwise fit into its memory.

MacDNC provides a file server that runs on your Mac and can serve files to a machine tool. When MacDNC is first run it will create a folder on your Desktop called 'MacDNC Files'. To make a program available 

## Installation

Run the following from Terminal:

    $ gem install mac_dnc
    $ macdnc setup

The `macdnc setup` line will creat a folder on your Desktop called `MacDNC Files`, this is where you put files when you want to make them available to your machine too. It will also create a program launcher icon in your Applications folder.

## Usage

MacDNC provides a file server that runs on your Mac and can serve files to a machine tool. When MacDNC is first run it will create a folder on your Desktop called 'MacDNC Files'. To make a program available to your machine tool simply copy or save it into this folder.

Then launch MacDNC by double clicking the program file.

Now on your Fadal press 'manual' until you see the 'enter next command' prompt. Then type:

    CD,10

To open a connection to the MacDNC server. You can then get a listing of the available programs by typing:

    DIR+

This will return a directory listing like so:

    TODO: ADD DIRECTORY LISTING

To transfer a file into the memory of the machine you can then type:

    TA,[PROGRAM NUMBER]

To execute a file via DNC simply type:

    DNC,[PROGRAM NUMBER]

## Command line usage

If you would like to send a file from the computer without initiating the transfer from the Fadal you can do so from Terminal by using the `macdnc` command like so:

    macdnc MODE path/of/file/to/send

The MODE variable is either TA (TAPE, store the program on the control) or DNC (Drip-feed, execute the program but do not store it).

Before using macdnc from the command line you need to make sure your Fadal is in command mode by pressing 'manual' until you see the 'enter next command' prompt.

## Programmatic usage

Here's where things really get fun! MacDNC can also be used to programatically stream data to a machine tool using the Ruby programming language like so:

    require 'macdnc'

    connection = MacDNC.new("/dev/cu.usbserial0") # Open a new serial connection using the default settings
    connection.initialize_dnc_connection
    connection.stream_data("G1\rX1.0Y1.0\rX0.0Y0.0\rM0")
    connection.close

This is how the MacDNC program works internally. Having this capability allows you to use a Fadal machining center for general purpose automation, and even for precision measuring tasks with the addition of a touch probe. The possibilities here are endless.

For the most part the code is not specific to Fadal machines, so it should either work out of the box with many other machine tools or be easily adapted!

## Liability

Please note this software is provided AS-IS, no warranties are expressed or implied. In no event shall I be held liable for any claim, damages, or other liability. Machine tools are dangerous, use this software at your own risk. See 'LICENSE.TXT' for more details.

## Contributing

1. Fork it ( https://github.com/aarongough/mac_dnc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
