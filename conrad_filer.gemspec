# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "conrad_filer/version"

Gem::Specification.new do |s|
  s.name        = "conrad_filer"
  s.version     = ConradFiler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jon Raiford"]
  s.email       = ["jon@raiford.org"]
  s.homepage    = ""
  s.summary     = %q{PRE-ALPHA - Do not use}
  s.description = %q{PRE-ALPHA - Do not use!  Think of it as applying a firewall ruleset to file management.}

  #s.add_runtime_dependency "ruby-inotify"
  #s.add_development_dependency "rspec", "~>2.5.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
