# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth-impak/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-impak"
  spec.version       = Omniauth::Impak::VERSION
  spec.authors       = ["Eugene Correia"]
  spec.email         = ["ecorreia@blueskybroadcast.com"]
  spec.summary       = %q{IMPak SSO}
  spec.description   = %q{IMPak SSO}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth', '~> 1.0'
  spec.add_dependency 'omniauth-oauth2', '~> 1.0'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'nokogiri'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
