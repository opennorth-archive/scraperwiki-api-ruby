# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "scraperwiki-api/version"

Gem::Specification.new do |s|
  s.name        = "scraperwiki-api"
  s.version     = ScraperWiki::API::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Open North"]
  s.email       = ["info@opennorth.ca"]
  s.homepage    = "http://github.com/opennorth/scraperwiki-api-ruby"
  s.summary     = %q{The ScraperWiki API Ruby Gem}
  s.description = %q{A Ruby wrapper for the ScraperWiki API}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('httparty', '~> 0.7.8')
  s.add_development_dependency('rspec', '~> 2.10.0')
end
