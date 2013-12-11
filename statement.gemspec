# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statement/version'

Gem::Specification.new do |spec|
  spec.name          = "statement"
  spec.version       = Statement::VERSION
  spec.authors       = ["Derek Willis"]
  spec.email         = ["dwillis@gmail.com"]
  spec.description   = %q{Crawls congressional websites for press releases.}
  spec.summary       = %q{Given a url, Statement returns links to press releases and official statements.}
  spec.homepage      = ""
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_dependency "rake"
  spec.add_dependency 'webmock'
  spec.add_dependency 'minitest'
  spec.add_dependency "american_date"
  if RUBY_VERSION > "1.8.7"
    spec.add_dependency "nokogiri"
  else
    spec.add_dependency "nokogiri", '~> 1.5.10'
  end
  spec.add_dependency "koala"
  spec.add_dependency "oj"
  spec.add_dependency "twitter"
  spec.add_dependency "typhoeus"
end
