# -*- coding: utf-8 -*-

require "fileutils"

module S7
  # 設定を表現する。
  class Configuration
    # デフォルトの秘密鍵暗号方式。
    DEFAULT_CIPHER_TYPE = "AES-256-CBC"
    
    # World オブジェクト。
    attr_accessor :world

    # 秘密鍵暗号方式。
    attr_accessor :cipher_type
    
    def initialize(world)
      @world = world
      @cipher_type = DEFAULT_CIPHER_TYPE
    end

    # 設定をファイルに書き出す。
    def save(path)
      hash = {
        "cipher_type" => @cipher_type,
      }
      FileUtils.touch(path)
      File.open(path, "wb") do |f|
        f.write(hash.to_yaml)
      end
    end
    
    # 設定をファイルから読み込む。
    def load(path)
      File.open(path, "rb") do |f|
        hash = YAML.load(f.read)
        @cipher_type = hash["cipher_type"]
      end
    end
  end
end
