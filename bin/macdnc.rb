#!/usr/bin/env ruby

require "bundler/setup"
require 'commander/import'
require 'mac_dnc'

program :version, MacDNC::VERSION
program :description, 'A simple DNC server.'
 
command :setup do |c|
  c.syntax = 'macdnc setup [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    MacDNC.new.setup()
  end
end

command :listen do |c|
  c.syntax = 'macdnc listen [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    dnc = MacDNC.new()
    dnc.load_config()
    #path = dnc.file_path_for_number(1)
    #dnc.send_file(:dnc, path)
    dnc.create_connection()
    dnc.listen()
    sleep 10
  end
end

