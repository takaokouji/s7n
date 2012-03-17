# -*- coding: utf-8 -*-

require "gettext"

module S7
  # s7で定義する例外クラスの親クラス。
  class ApplicationError < StandardError
    include GetText
  end

  # 不正なパスフレーズを表現する例外クラス。
  class InvalidPassphrase < ApplicationError
    def to_s
      return _("Invlaid passphrase.")
    end
  end

  # 不正なパスを表現する例外クラス。
  class InvalidPath < ApplicationError
    def initialize(path)
      @path = path
    end
    
    def to_s
      return _("Invalid path: path=<%s>") % @path
    end
  end

  # ファイルやディレクトリが存在しないことを表現する例外クラス。
  class NotExist < ApplicationError
    def initialize(path)
      @path = path
    end
    
    def to_s
      return _("Does not exit: path=<%s>") % @path
    end
  end

  # 機密情報が存在しないことを表現する例外クラス。
  class NoSuchEntry < ApplicationError
    def initialize(options = {})
      @options = options
    end
    
    def to_s
      if !@options.empty?
        s = ""
        @options.each do |key, value|
          s << " #{key}=<#{value}>"
        end
      end
      if s.empty?
        return _("No such entry.")
      else
        return _("No such entry:%s") % s
      end
    end
  end

  # 機密情報の属性が存在しないことを表現する例外クラス。
  class NoSuchAttribute < ApplicationError
    def initialize(options = {})
      @options = options
    end
    
    def to_s
      if !@options.empty?
        s = ""
        @options.each do |key, value|
          s << " #{key}=<#{value}>"
        end
      end
      if s.empty?
        return _("No such attribute.")
      else
        return _("No such attribute:%s") % s
      end
    end
  end

  # データ長が不正であることを表現する例外クラス。
  class DataLengthError < ApplicationError
    def initialize(actual, needed)
      @actual = actual
      @needed = needed
    end

    def to_s
      return _("Invalid data length: actual=<%s> needed=<%s>") % [@actual, @needed]
    end
  end

  # キャンセルを表現する例外クラス。
  class Canceled < ApplicationError
    MESSAGE = _("Canceled.")
    
    def to_s
      return MESSAGE
    end
  end

  # OS のコマンドの実行に失敗したことを表現する例外クラス。
  class CommandFailed < ApplicationError
    # command:: 失敗したコマンド
    # status:: コマンドの終了ステータス
    def initialize(command, status)
      @command = command
      @status = status
    end

    def to_s
      return _("Failed the command: command=<%s> status=<%d>") % [@command, @status]
    end
  end
end
