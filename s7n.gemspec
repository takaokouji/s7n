# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "s7n/version"

Gem::Specification.new do |s|
  s.name        = "s7n"
  s.version     = S7n::VERSION
  s.authors     = ["Kouji Takao"]
  s.email       = ["kouji@takao7.net"]
  s.homepage    = ""
  s.summary     = %q{The secret informations manager.}
  s.description = %q{s7 (seven) is the secret informations(password, credit number, file, etc..) manager.}

  s.rubyforge_project = "s7n"

  s.files         = `git ls-files`.split("\n") + Dir.glob("data/locale/**/*.mo")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.default_executable = "s7ncli"
  s.requirements << "Ruby, version 1.9.3 (or newer)"
  s.required_ruby_version = '>= 1.9.3'

  # specify any dependencies here; for example:
  s.add_development_dependency "test-unit"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "rr"
  s.add_development_dependency "test-unit-rr"
  s.add_runtime_dependency "gettext"
end
