require 'base64'
require 'encryptor'
require 'json'
require 'sidekiq-field-encryptor/version'

# This middleware configures encryption of any fields that can contain sensitive
# information. Keys in the hash are Sidekiq job classes and values are hashes
# that map indices in the args array to either "true" (encrypt the entire arg)
# or a list of keys (encrypt certain values in a hash argument). For example,
# the configuration hash:
#
#   { 'Job::Foo' => { 0 => true, 3 => [ 'secret', 'id' ] } }
#
# When applied to the Sidekiq job:
#
#   {
#     'class' => 'Job::Foo',
#     'args' => [{'x' => 1}, 'y', 'z', { 'public' => 'a', 'secret' => 'b' }],
#     ...
#   }
#
# Will encrypt the values {'x' => 1} and 'b' when storing the job in Redis and
# decrypt the values inside the client before the job is executed.
module SidekiqFieldEncryptor
  SERIALIZE_JSON = 'json'.freeze
  SERIALIZE_MARHSALL = 'marshal'.freeze

  class Base
    def initialize(options = {})
      @encryption_key = options[:encryption_key]
      @encrypted_fields = options[:encrypted_fields] || {}
      @encryption_algorithm = options[:encryption_algorithm] || 'aes-256-gcm'

      @serialization_method = options[:serialization_method] || SERIALIZE_JSON
      @serialization_compat = options[:serialization_compat]
    end

    def assert_key_configured
      raise 'Encryption key not configured' if @encryption_key.nil?
    end

    def serialize(value)
      case @serialization_method
      when SERIALIZE_JSON
        JSON.generate(value, quirks_mode: true)
      when SERIALIZE_MARHSALL
        Marshal.dump(value)
      else
        raise "Invalid serialization_method: #{@serialization_method}"
      end
    end

    def deserialize(method, value)
      if !@serialization_compat && method != @serialization_method
        raise "Invalid serialization_method received: #{method}"
      end

      case method
      when SERIALIZE_JSON
        JSON.parse(value, quirks_mode: true)
      when SERIALIZE_MARHSALL, nil
        # No method used to be Marshall, so we respect this here
        Marshal.load(value) # rubocop:disable Security/MarshalLoad
      else
        raise "Invalid serialization_method: #{@serialization_method}"
      end
    end

    def encrypt(value)
      plaintext = serialize(value)
      iv = OpenSSL::Cipher::Cipher.new(@encryption_algorithm).random_iv
      args = { key: @encryption_key, iv: iv, algorithm: @encryption_algorithm }
      ciphertext = ::Encryptor.encrypt(plaintext, **args)
      [
        ::Base64.encode64(ciphertext),
        ::Base64.encode64(iv),
        @serialization_method
      ]
    end

    def decrypt(encrypted)
      base64_ciphertext, base64_iv, serialization_method = encrypted
      ciphertext = ::Base64.decode64(base64_ciphertext)
      iv = ::Base64.decode64(base64_iv)
      args = { key: @encryption_key, iv: iv, algorithm: @encryption_algorithm }
      plaintext = ::Encryptor.decrypt(ciphertext, **args)
      deserialize(serialization_method, plaintext)
    end

    def process_message(message)
      fields = @encrypted_fields[message['class']]
      return unless fields

      assert_key_configured
      message['args'].size.times.each do |arg_index|
        to_encrypt = fields[arg_index]
        next unless to_encrypt

        raw_value = message['args'][arg_index]
        if to_encrypt == true
          message['args'][arg_index] = yield(raw_value)
        elsif to_encrypt.is_a?(Array) && raw_value.is_a?(Hash)
          message['args'][arg_index] = Hash[raw_value.map do |key, value|
            value = yield(value) if to_encrypt.member?(key.to_s)
            [key, value]
          end]
        end
      end
    end
  end

  class Client < Base
    def call(_, message, _, _)
      process_message(message) { |value| encrypt(value) }
      yield
    end
  end

  class Server < Base
    def call(_, message, _)
      process_message(message) { |value| decrypt(value) }
      yield
    end
  end
end
