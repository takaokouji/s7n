# -*- coding: utf-8 -*-

require "openssl"

module S7n
  # 秘密鍵暗号化方式を用いた暗号化処理を表現する。
  class Cipher
    @@cipher_classes = {}

    class << self
      def create_instance(type, options)
        return @@cipher_classes[type].new(options)
      end

      private
      
      def cipher_type(name)
        if @@cipher_classes.nil?
          @@cipher_classes = {}
        end
        @@cipher_classes[name] = self
        self.const_set("CIPHER_TYPE", name)
      end
    end

    attr_accessor :options

    def initialize(options)
      self.options = options
    end

    # io で指定した IO からデータを読み込み、復号する。
    def decrypt(io)
      begin
        cipher = create_cipher
        cipher.decrypt
        parse_options(cipher, options)
        s = ""
        while d = io.read(cipher.block_size)
          s << cipher.update(d)
        end
        s << cipher.final
      rescue OpenSSL::Cipher::CipherError
        raise InvalidPassphrase
      end
      return s
    end

    # io で指定した IO からデータを読み込み、暗号化する。
    def encrypt(io)
      cipher = create_cipher
      cipher.encrypt
      parse_options(cipher, options)
      s = ""
      while d = io.read(cipher.block_size)
        s << cipher.update(d)
      end
      s << cipher.final
      return s
    end

    private

    def create_cipher
      cipher_type = self.class.const_get("CIPHER_TYPE")
      return OpenSSL::Cipher::Cipher.new(cipher_type)
    end
    
    def parse_options(cipher, options)
      if options.key?(:passphrase)
        cipher.pkcs5_keyivgen(options[:passphrase])
      elsif options.key?(:key)
        cipher.key_len = options[:key].length
        cipher.key = options[:key].key
        if options.key?(:iv)
          cipher.iv = options[:iv]
        end
      else
        raise ArgumentError, "too few options: :passphrase or :key"
      end
      if options.key?(:padding)
        cipher.padding = options[:padding]
      end
    end
  end

  # 秘密鍵方式の一つ AES を用いて暗号化処理を行うクラスを表現する。
  class Aes256CbcCipher < Cipher
    cipher_type "AES-256-CBC"
  end

  # 秘密鍵方式の一つ Blowfish を用いて暗号化処理を行うクラスを表現する。
  class BfCbcCipher < Cipher
    cipher_type "BF-CBC"
  end

  # Cipher クラスと同じインタフェースを持つが、暗号化しないクラスを表現
  # する。
  class PlainCipher < Cipher
    cipher_type "plain"

    def encrypt(io)
      return io.read
    end

    def decrypt(io)
      return io.read
    end
  end
end
