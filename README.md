# ![](https://raw.github.com/aptible/straptible/master/lib/straptible/rails/templates/public.api/icon-60px.png) Sidekiq::Field::Encryptor

[![Gem Version](https://badge.fury.io/rb/sidekiq-field-encryptor.png)](https://rubygems.org/gems/sidekiq-field-encryptor)
[![Build Status](https://travis-ci.org/aptible/sidekiq-field-encryptor.png?branch=master)](https://travis-ci.org/aptible/sidekiq-field-encryptor)
[![Dependency Status](https://gemnasium.com/aptible/sidekiq-field-encryptor.png)](https://gemnasium.com/aptible/sidekiq-field-encryptor)

This is a utility which is intended to be used for encrypting sensitive data in Sidekiq jobs. The data is encrypted before sending it to Redis, and decrypted right before the Sidekiq job is executed.

## Installation

Add the following line to your application's Gemfile.

    gem 'sidekiq-field-encryptor'

And then run `bundle install`.

## Usage

This middleware configures encryption of any fields that can contain sensitive
information. Keys in the hash are Sidekiq job classes and values are hashes
that map indices in the args array to either "true" (encrypt the entire arg)
or a list of keys (encrypt certain values in a hash argument). For example,
the configuration hash:

    { 'Job::Foo' => { 0 => true, 3 => [ 'secret', 'id' ] } }

When applied to the Sidekiq job:

    {
      'class' => 'Job::Foo',
      'args' => [{'x' => 1}, 'y', 'z', { 'public' => 'a', 'secret' => 'b' }],
      ...
    }

Will encrypt the values {'x' => 1} and 'b' when storing the job in Redis and
decrypt the values inside the client before the job is executed.

## Contributing

1. Fork the project.
1. Commit your changes, with specs.
1. Ensure that your code passes specs (`rake spec`) and meets Aptible's Ruby style guide (`rake rubocop`).
1. Create a new pull request on GitHub.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2019 [Aptible](https://www.aptible.com), Blake Pettersson, and contributors.
