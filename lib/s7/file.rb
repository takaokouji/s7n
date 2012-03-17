require "s7/exception"

module S7
  class File
    # パスワードコレクションのファイルのバージョン。
    VERSION = "1.1.0"
      
    # パスワードコレクションの先頭記述するマジック文字列。
    MAGIC = "GPassFile version #{VERSION}"

    # Cipherで使用するIV(Initial Vector)
    IV = [5, 23, 1, 123, 12, 3, 54, 94].pack("C8")

    # パスワードコレクションを格納するファイルを作成する。
    # +path+:: 作成するファイルのパスを文字列で指定する。
    # +passphrase+:: ファイルを暗号化するマスターパスフレーズを
    #                文字列で指定する。
    #
    # すでにファイルが存在した場合、例外を発生させる。
    def self.create(path, passphrase)
      path = ::File.expand_path(path)
      if ::File.exist?(path)
        raise S7::Exception, "already exist file or directory: #{path}"
      end
      ::File.open(path, "w") do |f|
        key = S7::Key.create_instance("SHA-1", passphrase)
        cipher =
          S7::Cipher.create_instance("BF-CBC", :key => key, :iv => S7::File::IV)
        magic = cipher.encrypt(StringIO.new(S7::File::MAGIC))
        f.write(magic)
      end
    end

    def self.open(path, passphrase)
      path = ::File.expand_path(path)
      if !::File.exist?(path)
        raise S7::Exception, "no such file or directory: #{path}"
      end
      if !block_given?
        raise ArgumentError, "no block given"
      end
      begin
        f = self.new(path, passphrase)
        yield(f)
      ensure
        f.close
      end
    end

    # パスワードコレクションのパス。
    attr_accessor :path

    # パスフレーズから生成したCipher用のキー。
    attr_accessor :key

    # キーとIVから生成したCipher。
    attr_accessor :cipher

    # 操作対象のファイル。
    attr_accessor :file

    def initialize(path, passphrase)
      self.path = ::File.expand_path(path)
      self.key = S7::Key.create_instance("SHA-1", passphrase)
      self.cipher = S7::Cipher.create_instance("BF-CBC", :key => key,
                                               :iv => S7::File::IV)
      self.file = nil
    end

    # ファイルを閉じる。
    def close
      if self.file
        self.file.close
      end
    end
  end
end
