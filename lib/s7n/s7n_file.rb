# -*- coding: utf-8 -*-

require "fileutils"
require "stringio"
require "s7n/utils"
require "s7n/cipher"

module S7n
  # s7 オリジナルのファイル形式で機密情報の読み書きを表現する。
  module S7nFile
    # マジック。
    MAGIC = "s7 file version 0\n"

    # data で指定したバイト列を暗号化して書き込む。
    def write(path, master_key, cipher_type, data)
      cipher = Cipher.create_instance(cipher_type, :passphrase => master_key)
      FileUtils.touch(path)
      File.open(path, "r+b") do |f|
        f.flock(File::LOCK_EX)
        data = [MAGIC,
                cipher_type + "\n",
                cipher.encrypt(StringIO.new(data))].join
        f.write(data)
        f.flush
        f.truncate(f.pos)
      end
      FileUtils.chmod(0600, path)
    end
    module_function :write

    # path で指定したファイルを読み込み、master_key で指定したマスター
    # キーを使用して復号する。
    def read(path, master_key)
      File.open(path, "rb") do |f|
        f.flock(File::LOCK_EX)
        magic = f.gets
        if MAGIC != magic
          raise InvalidPassphrase
        end
        cipher_type = f.gets.chomp
        cipher = Cipher.create_instance(cipher_type,
                                        :passphrase => master_key)
        return cipher.decrypt(f)
      end
    end
    module_function :read
  end
end
