# -*- coding: utf-8 -*-

require "date"
require "gettext"

module S7
  # 属性を表現する。
  class Attribute
    include GetText

    # サポートしている属性のクラス。
    @@attribute_classes = {}

    class << self
      def create_instance(type, options)
        return @@attribute_classes[type].new(options)
      end

      # 属性の型名の配列を返す。
      def types
        return @@attribute_classes.keys
      end
      
      private
      
      def type(name)
        @@attribute_classes[name] = self
        self.const_set("TYPE", name)
      end
    end
    
    # 名前。
    attr_accessor :name

    # 機密情報かどうか。true であれば機密情報、false であればそうでない。
    attr_accessor :secret

    # 値を編集できるかどうか。true であれば編集でき、false であれ
    # ばそうでない。
    attr_accessor :editabled

    # 削除できるかどうか。true であれば削除できず、false であれ
    # ばそうでない。
    attr_accessor :protected

    def initialize(options)
      self.name = options["name"]
      self.value = options["value"]
      self.secret = options["secret"] ? true : false
      if options.key?("editabled")
        self.editabled = options["editabled"] ? true : false
      else
        self.editabled = true
      end
      self.protected = options["protected"] ? true : false
    end

    # value を取得する。
    def value
      if @value.nil?
        return nil
      else
        return get_value
      end
    end

    # value を設定する。
    def value=(val)
      if val.nil?
        @value = val
      else
        set_value(val)
      end
    end

    # 属性の型を取得する。
    def type
      return self.class.const_get("TYPE")
    end
    
    # 機密情報かどうかを取得する。
    # 機密情報の場合、true を返す。そうでなれば false を返す。
    def secret?
      return secret ? true : false
    end

    # ユーザによる値の編集ができるかどうかを取得する。
    # 編集できる場合、true を返す。そうでなければ true を返す。
    def editable?
      return editabled ? true : false
    end

    # ユーザによる削除ができるかどうかを取得する。
    # 削除できる場合、true を返す。そうでなければ true を返す。
    def protected?
      return protected ? true : false
    end

    # value を表示するために文字列に変換する。
    # このとき、 secret が true であれば「*」でマスクする。
    def display_value(secret = @secret)
      if secret
        return "*" * value.to_s.length
      else
        return value.to_s
      end
    end

    private

    def get_value
      return @value
    end

    def set_value(val)
      @value = val
    end
  end

  # 文字列の属性を表現する。
  class TextAttribute < Attribute
    type("text")

    private
    
    def get_value
      return @value.to_s.force_encoding("utf-8")
    end

    def set_value(val)
      @value = val.to_s.dup.force_encoding("utf-8")
    end
  end

  # 数値の属性を表現する。
  class NumericAttribute < Attribute
    type("numeric")

    private
    
    def get_value
      return @value.to_i
    end

    def set_value(val)
      @value = val.to_i
    end
  end

  # 真偽値の属性を表現する。
  class BooleanAttribute < Attribute
    type("boolean")

    # value を表示するために文字列に変換する。
    # secret が true であれば「*」を返す。
    # そうでなければ、Yes か No を返す。
    def display_value(secret = @secret)
      if secret
        return "*"
      else
        return value ? _("Yes") : _("No")
      end
    end

    private

    def get_value
      return @value ? true : false
    end

    def set_value(val)
      @value = val ? true : false
    end
  end

  # 日時の属性を表現する。
  class DateTimeAttribute < Attribute
    type("datetime")

    # value を表示するために文字列に変換する。
    # secret が true であれば「*」を返す。
    # そうでなければ、「%Y/%m/%d %H:%M:%S」でフォーマットした文字列を返す。
    # また、時分秒が全て0の場合は「%Y/%m/%d」でフォーマットする。
    def display_value(secret = @secret)
      if secret
        return "*"
      else
        format = "%Y/%m/%d"
        if value.hour != 0 || value.min != 0 || value.sec != 0
          format << " %H:%M:%S"
        end
        return value.strftime(format)
      end
    end

    private

    def get_value
      return @value.to_datetime
    end
    
    def set_value(val)
      case val
      when Time, DateTime, Date
        @value = val.to_datetime
      else
        @value = DateTime.parse(val.to_s)
      end
    end
  end

  # ファイルの属性を表現する。
  class FileAttribute < Attribute
    type("file")
  end

  # 画像の属性を表現する。
  class FigureAttribute < FileAttribute
    type("figure")
  end

  # 不明な属性を表現する。
  class UnknownAttribute < Attribute
    type("unknown")
  end
end
