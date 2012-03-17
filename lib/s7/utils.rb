# -*- coding: utf-8 -*-

require "gettext"
require "s7/exception"

module S7
  # 便利なメソッドの集合。
  module Utils
    include GetText
    
    # 実行したユーザのホームディレクトリを返す。
    def home_dir
      return File.expand_path("~")
    end
    module_function :home_dir

    # str で指定した文字列の内容を破壊する。
    # メモリ上のパスフレーズをクリアするために使用する。
    def shred_string(str)
      # TODO: OpenSSL などを使用してまともな実装にする。
      str.length.times do |i|
        str[i] = "1"
      end
    end
    module_function :shred_string

    # command で指定したコマンドを実行する。
    # 終了コードが 0 でなければ、ApplicationError 例外を発生させる。
    def execute(command)
      system(command)
      if $? != 0
        raise ApplicationError, _("failed execute: command=<%s>") % command
      end
    end
    module_function :execute
  end
end
