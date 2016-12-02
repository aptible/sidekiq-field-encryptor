require 'spec_helper'

describe SidekiqFieldEncryptor::Client do
  let(:key) { OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_key }
  let(:message) do
    { 'class' => 'FooJob', 'args' => [1, 2, { 'a' => 'A', 'b' => 'B' }] }
  end

  describe 'with no encryption key' do
    it "doesn't fail when encryption isn't attempted" do
      subject.call('FooJob', message, nil, nil) {}
    end
    it 'fails when encryption is attempted' do
      client = SidekiqFieldEncryptor::Client.new(
        encrypted_fields: { 'FooJob' => { 1 => true } }
      )
      expect { client.call('FooJob', message, nil, nil) {} }
        .to raise_error('Encryption key not configured')
    end
  end

  describe 'with an encryption key' do
    subject do
      SidekiqFieldEncryptor::Client.new(
        encryption_key: key,
        encrypted_fields: { 'FooJob' => { 1 => true, 2 => %w(b d) } }
      )
    end

    it 'encrypts only fields specified by the encryption config' do
      subject.call('FooJob', message, nil, nil) {}
      expect(message['args'][0]).to eq(1)
      expect(subject.decrypt(message['args'][1])).to eq(2)
      expect(message['args'][2]['a']).to eq('A')
      expect(subject.decrypt(message['args'][2]['b'])).to eq('B')
    end
  end

  it 'supports setting the encryption algorithm' do
    key = OpenSSL::Cipher::Cipher.new('aes-128-cbc').random_key
    fields = { 'FooJob' => { 1 => true, 2 => %w(b d) } }

    ko = SidekiqFieldEncryptor::Client.new(
      encryption_key: key,
      encryption_algorithm: 'aes-256-cbc',
      encrypted_fields: fields
    )

    ok = SidekiqFieldEncryptor::Client.new(
      encryption_key: key,
      encryption_algorithm: 'aes-128-cbc',
      encrypted_fields: fields
    )

    expect { ko.call('FooJob', message, nil, nil) {} }
      .to raise_error(/must be 32 bytes or longer/)

    ok.call('FooJob', message, nil, nil) {}
  end
end

describe SidekiqFieldEncryptor::Server do
  let(:key) { OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_key }
  let(:message) do
    { 'class' => 'FooJob', 'args' => [1, 2, { 'a' => 'A', 'b' => 'B' }] }
  end

  describe 'with no encryption key' do
    it "doesn't fail when decryption isn't attempted" do
      subject.call('FooJob', message, nil) {}
    end
    it 'fails when decryption is attempted' do
      server = SidekiqFieldEncryptor::Server.new(
        encrypted_fields: { 'FooJob' => { 1 => true } }
      )
      expect { server.call('FooJob', message, nil) {} }
        .to raise_error('Encryption key not configured')
    end
  end

  describe 'with an encryption key' do
    subject do
      SidekiqFieldEncryptor::Server.new(
        encryption_key: key,
        encrypted_fields: { 'FooJob' => { 1 => true, 2 => %w(b d) } }
      )
    end

    it 'decrypts all fields specified by the encryption config' do
      original_message = message.dup
      message['args'][1] = subject.encrypt(message['args'][1])
      message['args'][2]['b'] = subject.encrypt(message['args'][2]['b'])
      subject.call('FooJob', message, nil) {}
      expect(message).to eq(original_message)
    end

    it 'supports setting the encryption algorithm' do
      key = OpenSSL::Cipher::Cipher.new('aes-128-cbc').random_key
      fields = { 'FooJob' => { 1 => true } }

      ko = SidekiqFieldEncryptor::Server.new(
        encryption_key: key,
        encryption_algorithm: 'aes-256-cbc',
        encrypted_fields: fields
      )

      ok = SidekiqFieldEncryptor::Server.new(
        encryption_key: key,
        encryption_algorithm: 'aes-128-cbc',
        encrypted_fields: fields
      )

      message['args'][1] = ok.encrypt(message['args'][1])

      expect { ko.call('FooJob', message, nil) {} }
        .to raise_error(/key must be 32 bytes or longer/)

      ok.call('FooJob', message, nil) {}
    end
  end
end
