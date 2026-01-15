# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/json_associations/version'

Gem::Specification.new do |spec|
  spec.name          = "active_record-json_associations"
  spec.version       = ActiveRecord::JsonAssociations::VERSION
  spec.authors       = ["Micah Geisel"]
  spec.email         = ["micah@botandrose.com"]
  spec.summary       = %q{Instead of a many-to-many join table, serialize the ids into a JSON array.}
  spec.description   = %q{Instead of a many-to-many join table, serialize the ids into a JSON array.}
  spec.homepage      = "https://github.com/botandrose/active_record-json_associations"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "trilogy"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "timecop"
end

