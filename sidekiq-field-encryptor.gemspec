# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'English'
require 'sidekiq-field-encryptor/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-field-encryptor'
  spec.version       = SidekiqFieldEncryptor::VERSION
  spec.authors       = ['Blake Pettersson']
  spec.email         = ['blake@aptible.com']
  spec.description   = 'Selectively encrypt fields in Sidekiq'
  spec.summary       = 'Selectively encrypt fields sent into Sidekiq'
  spec.homepage      = 'https://github.com/aptible/sidekiq-field-encryptor'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.require_paths = ['lib']

  spec.add_dependency 'encryptor'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop-rspec'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
