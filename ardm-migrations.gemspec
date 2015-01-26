# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dm-migrations/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = 'ardm-migrations'
  gem.version       = DataMapper::Migrations::VERSION

  gem.authors = ["Martin Emde", "Paul Sadauskas"]
  gem.email = ['me@martinemde.com', 'psadauskas [a] gmail [d] com']
  gem.description = "Ardm fork of dm-migrations"
  gem.summary = gem.description
  gem.license = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {spec}/*`.split("\n")
  gem.extra_rdoc_files = %w[LICENSE README.rdoc]

  gem.homepage = "http://github.com/martinemde/ardm-migrations"

  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'ardm-core', '~> 1.2'

  gem.add_development_dependency 'rake',  '~> 0.9'
  gem.add_development_dependency 'rspec', '~> 1.3'
end

