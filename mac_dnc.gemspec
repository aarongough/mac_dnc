# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mac_dnc/version'

Gem::Specification.new do |spec|
  spec.name          = "mac_dnc"
  spec.version       = MacDNC::VERSION
  spec.authors       = ["Aaron Gough"]
  spec.email         = ["aaron.gough@gmail.com"]
  spec.summary       = %q{A DNC server for Mac OSX.}
  spec.description   = %q{A convenient DNC server for Mac OSX. Optimized for Fadal machine tools.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_dependency "serialport"
  spec.add_dependency "json"
  spec.add_dependency "commander"
end
