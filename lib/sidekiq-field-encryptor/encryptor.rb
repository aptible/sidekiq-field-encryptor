require 'base64'
require 'encryptor'
require 'sidekiq-field-encryptor/version'

module SidekiqFieldEncryptor
  class Base
    def initialize(options = {})
      @encryption_key = options[:encryption_key]
      @encrypted_fields = options[:encrypted_fields] || {}
    end

    def assert_key_configured
      fail 'Encryption key not configured' if @encryption_key.nil?
    end

    def encrypt(value)
      plaintext = Marshal.dump(value)
      iv = OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
      args = { key: @encryption_key, iv: iv }
      ciphertext = ::Encryptor.encrypt(plaintext, **args)
      [::Base64.encode64(ciphertext), ::Base64.encode64(iv)]
    end

    def decrypt(encrypted)
      ciphertext, iv = encrypted.map { |value| ::Base64.decode64(value) }
      args = { key: @encryption_key, iv: iv }
      plaintext = ::Encryptor.decrypt(ciphertext, **args)
      Marshal.load(plaintext)
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
