# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "epay/version"

Gem::Specification.new do |s|
  s.name        = "epay"
  s.version     = Epay::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary       = "Ruby client for ePay API"
  s.homepage      = "http://github.com/pfeiffer/epay"
  s.authors       = [ 'Mattias Pfeiffer' ]
  s.email         = 'mattias@netdate.dk'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]

  s.extra_rdoc_files  = [ "README.markdown" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_rubygems_version = ">= 1.3.6"

  # = Library dependencies
  #
  s.add_dependency "rest-client", "~> 1.6.0"
  s.add_dependency "activesupport", "~> 3"
  s.add_dependency "builder", "~> 2.1.2"

  # = Development dependencies
  #
  s.add_development_dependency "bundler",     "~> 1.0"
  s.add_development_dependency "yajl-ruby",   "~> 0.8.0"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock", "~>1.7"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "vcr", "~> 2.0.0.rc1"
  s.add_development_dependency "rake"

  # These gems are not needed for CI
  #
  unless ENV["CI"]
    s.add_development_dependency "guard"
    s.add_development_dependency "guard-rspec"
    s.add_development_dependency "rb-fsevent"
    s.add_development_dependency "rdoc"
    s.add_development_dependency "turn", "~> 0.9"
  end

  s.description = <<-DESC
    Ruby client for ePay API. Supports manipulating transactions and subscriptions.
  DESC
end