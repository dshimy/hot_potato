# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hot_potato/version"

Gem::Specification.new do |s|
  s.name        = "hot_potato"
  s.version     = HotPotato::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darian Shimy"]
  s.email       = ["dshimy@gmail.com"]
  s.homepage    = "http://github.com/dshimy/hotpotato"
  s.summary     = %q{A Real-time Processing Framework}
  s.description = %q{Hot Potato is an open source real-time processing framework written in Ruby. Originally designed to process the Twitter firehose at 3,000+ tweets per second, it has been extended to support any type of streaming data as input or output to the framework. The framework excels with applications such as, social media analysis, log processing, fraud prevention, spam detection, instant messaging, and many others that include the processing of streaming data.}

  s.add_dependency 'json'
  s.add_dependency 'redis'
  s.add_dependency 'bunny'
  s.add_dependency 'sinatra'
  s.add_dependency "vegas"
  s.add_dependency "snappy"

  s.rubyforge_project = "hot_potato"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
