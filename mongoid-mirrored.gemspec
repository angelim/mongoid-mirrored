# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid-mirrored/version"

Gem::Specification.new do |s|
  s.name        = "mongoid-mirrored"
  s.version     = Mongoid::Mirrored::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors = ["Alexandre Angelim"]
  s.email = %q{angelim@angelim.com.br}  
  s.homepage = %q{http://github.com/angelim/mongoid-mirrored}    
  s.summary = %q{Mirrored Embeds for Mongoid}  
  s.description = %q{Create mirrors of root documents embeded in other models and keep them in sync}
    
  s.rubyforge_project = "mongoid-mirrored"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency(%q<mongoid>, ["~> 2.0"])
  s.add_development_dependency("rspec", ["~> 2.6"])
  s.add_development_dependency("bson_ext", ["~> 1.3"])
end