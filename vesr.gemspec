# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'vesr/version'

Gem::Specification.new do |s|
  s.name        = "vesr"
  s.version     = Vesr::VERSION
  s.authors     = ["Roman Simecek", "Simon Hürlimann (CyT)"]
  s.email       = ["roman.simecek@cyt.ch", "simon.huerlimann@cyt.ch"]
  s.homepage    = "https://github.com/raskhadafi/vesr"
  s.licenses    = ["MIT"]
  s.summary     = "VESR invoice support library."
  s.description = "VESR provides support for ESR number calculations and gives ready to use Rails components."

  s.files        = `git ls-files app lib config`.split("\n")
  s.platform     = Gem::Platform::RUBY

  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
end
