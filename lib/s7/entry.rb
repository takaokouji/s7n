# -*- coding: utf-8 -*-

require "gettext"

module S7
  # 機密情報を表現する。
  class Entry
    include GetText
    
    # タグ名の配列。
    attr_reader :tags

    # 属性の配列。
    attr_reader :attributes

    def initialize
      @attributes = []
      attr = NumericAttribute.new("name" => N_("id"), "editabled" => false,
                                  "protected" => true)
      @attributes.push(attr)
      attr = TextAttribute.new("name" => N_("name"), "protected" => true)
      @attributes.push(attr)
      attr = NumericAttribute.new("name" => N_("rate"), "protected" => true,
                                  "value" => 1)
      @attributes.push(attr)
      
      @tags = []
    end

    # ID を取得する。
    def id
      return get_attribute("id").value
    end

    # ID を設定する。
    def id=(val)
      get_attribute("id").value = val
    end

    # name で指定した名前の属性を取得する。
    # 存在しない場合、nil を返す。
    def get_attribute(name)
      return @attributes.find { |attr| attr.name == name }
    end
    
    # attributes で指定した属性を追加する。
    # 名前が同じ属性が存在する場合、値を書き換える。
    # 名前が同じ属性が存在し、なおかつ型が異なる場合、ApplicationError
    # 例外を発生させる。
    def add_attributes(*attributes)
      [attributes].flatten.each do |attribute|
        attr = @attributes.find { |a|
          a.name == attribute.name
        }
        if attr
          if attr.class == attribute.class
            attr.value = attribute.value
          else
            raise ApplicationError, _("not same attribute type: name=<%s> exist=<%s> argument=<%s>") % [attr.name, attr.class, attribute.class]
          end
        else
          @attributes.push(attribute)
        end
      end
    end

    # 全ての属性の複製を取得する。
    def duplicate_attributes(exclude_uneditable = true)
      if exclude_uneditable
        attrs = @attributes
      else
        attrs = @attributes.select { |attr|
          attr.editable?
        }
      end
      return attrs.collect { |attr|
        a = attr.dup
        begin
          a.value = attr.value.dup
        rescue TypeError
        end
        a
      }
    end

    def method_missing(symbol, *args)
      attr_name = symbol.to_s
      if attr_name[-1] == "="
        attr_name = attr_name[0..-2]
        setter = true
      end
      attr = @attributes.find { |a|
        a.name == attr_name
      }
      if attr
        if setter
          attr.value = args.first
        else
          return attr.value
        end
      else
        super
      end
    end
  end
end
