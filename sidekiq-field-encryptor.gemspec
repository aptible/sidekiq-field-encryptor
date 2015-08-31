# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'English'
require 'sidekiq/field/encryptor/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-field-encryptor'
  spec.version       = Sidekiq::Field::Encryptor::VERSION
  spec.authors       = ['Blake Pettersson']
  spec.email         = ['blake.pettersson@gmail.com']
  spec.description   = 'TODO: Write a gem description'
  spec.summary       = 'TODO: Write a gem summary'
  spec.homepage      = 'https://github.com/aptible/sidekiq-field-encryptor'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'aptible-tasks'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
