# -*- coding: utf-8 -*-

require "openssl"

module S7
  # 暗号化用のキーを表現する。
  class Key
    @@key_classes = {}
    
    class << self
      def create_instance(type, passphrase)
        return @@key_classes[type].new(passphrase)
      end

      private
      
      def key_type(name)
        if @@key_classes.nil?
          @@key_classes = {}
        end
        @@key_classes[name] = self
        self.const_set("KEY_TYPE", name)
      end
    end

    attr_reader :key
    attr_reader :length

    def initialize(passphrase)
      @key = OpenSSL::Digest.digest(hash_type, passphrase)
      @length = @key.length
    end

    private

    def hash_type
      begin
        return self.class.const_get("HASH_TYPE")
      rescue NameError
        return self.class.const_get("KEY_TYPE")
      end
    end
  end

  class Md5Key < Key
    key_type "MD5"
  end

  class Sha1Key < Key
    key_type "SHA-1"
    HASH_TYPE = "SHA1"
  end

  begin
    OpenSSL::Digest.const_get("SHA224")

    class Sha224Key < Key
      key_type "SHA-224"
      HASH_TYPE = "SHA224"
    end
  rescue NameError
  end

  begin
    OpenSSL::Digest.const_get("SHA256")
    
    class Sha256Key < Key
      key_type "SHA-256"
      HASH_TYPE = "SHA256"
    end
  rescue NameError
  end
  
  begin
    OpenSSL::Digest.const_get("SHA512")
    
    class Sha512Key < Key
      key_type "SHA-512"
      HASH_TYPE = "SHA512"
    end
  rescue NameError
  end
end
