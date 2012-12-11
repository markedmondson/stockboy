# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "stockboy/version"

Gem::Specification.new do |s|
  s.name        = "stockboy"
  s.version     = Stockboy::VERSION
  s.authors     = ["Andrew Vit"]
  s.email       = ["andrew@avit.ca"]
  s.homepage    = ""
  s.summary     = %q{Multi-source data normalization library}
  s.description = %q{Supports importing data over various transports with key-value remapping & normalization}

  s.rubyforge_project = "stockboy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # TODO: document it
  s.has_rdoc = false

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "savon_spec"
  # s.add_development_dependency "vcr"

  s.add_runtime_dependency "log4r"
  s.add_runtime_dependency "savon"
  s.add_runtime_dependency "mail"
  s.add_runtime_dependency "activemodel"
end
