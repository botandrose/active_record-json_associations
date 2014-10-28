# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/json_has_many/version'

Gem::Specification.new do |spec|
  spec.name          = "active_record-json_has_many"
  spec.version       = ActiveRecord::JsonHasMany::VERSION
  spec.authors       = ["Micah Geisel"]
  spec.email         = ["micah@botandrose.com"]
  spec.summary       = %q{Instead of a many-to-many join table, serialize the ids into a JSON array.}
  spec.description   = %q{Instead of a many-to-many join table, serialize the ids into a JSON array.}
  spec.homepage      = "https://github.com/botandrose/active_record-json_has_many"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end

