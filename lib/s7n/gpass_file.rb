# -*- coding: utf-8 -*-

require "s7n/key"
require "s7n/cipher"
require "s7n/entry_collection"
require "s7n/attribute"
require "s7n/exception"
require "gettext"

module S7n
  # GPass のファイルに関する処理を表現する。
  class GPassFile
    include GetText
    
    # GPass のファイルが格納されているデフォルトのパス。
    DEFAULT_PATH = "~/.gpass/passwords.gps"

    # Blowfish の初期化配列。
    IV = [5, 23, 1, 123, 12, 3, 54, 94].pack("C8")

    # GPass のファイルであることを示すマジック。
    MAGIC_PATTERN = /\AGPassFile version (\d\.\d\.\d)/
    
    # GPass で扱う秘密情報の種類と属性。
    ENTRY_ATTRIBUTE_TEMPLATES = { 
      "entry" => [TextAttribute.new("name" => N_("name")),
                  TextAttribute.new("name" => N_("description")),
                  DateTimeAttribute.new("name" => N_("created_at")),
                  DateTimeAttribute.new("name" => N_("updated_at")),
                  BooleanAttribute.new("name" => N_("expiration")),
                  DateTimeAttribute.new("name" => N_("expire_at"))],
      "folder" => ["entry"],
      "password" => ["entry",
                     TextAttribute.new("name" => N_("username")),
                     TextAttribute.new("name" => N_("password"),
                                       "secret" => true)],
      "general" => ["password",
                    TextAttribute.new("name" => N_("hostname"))],
      "shell" => ["general"],
      "website" => ["password",
                    TextAttribute.new("name" => N_("url"))],
    }
    
    ENTRY_ATTRIBUTE_TEMPLATES.each do |name, template|
      loop do
        replaced = false
        template.each_with_index do |attr, i|
          if attr.is_a?(String)
            template[i] = ENTRY_ATTRIBUTE_TEMPLATES[attr]
            replaced = true
          end
        end
        if replaced
          template.flatten!
        else
          break
        end
      end
    end
    
    def read(passphrase, path = DEFAULT_PATH)
      res = EntryCollection.new
      File.open(File.expand_path(path), "r") do |f|
        f.flock(File::LOCK_EX)
        s = decrypt(f, passphrase)
        parse(s, res)
      end
      return res
    end

    private

    def decrypt(io, passphrase)
      key = Key.create_instance("SHA-1", passphrase)
      cipher = Cipher.create_instance("BF-CBC", :key => key, :iv => IV)
      return cipher.decrypt(io)
    end

    def parse(s, entry_collection)
      if s.slice!(MAGIC_PATTERN).nil?
        raise InvalidPassphrase
      end
      version = $1
      # TODO: 1.1.0 より前のバージョンもサポートする。
      if version != "1.1.0"
        raise GPassFileError, _("not supported version: %s") % version
      end
      id_entry = {}
      while !s.empty?
        res = parse_gpass_entry(s)
        id = res["id"]
        entry = res["entry"]
        if id_entry.key?(id)
          raise GPassFileError, _("duplicated entry id: %s") % id
        end
        id_entry[id] = entry
        parent = id_entry[res["parent_id"]]
        if parent
          entry.tags.push(*parent.tags)
        end
        if res["type"] == "folder"
          entry.tags.push(entry.name)
        else
          entry_collection.add_entries(entry)
        end
      end
    end

    def parse_gpass_entry(s)
      id = unpack_number(s)
      parent_id = unpack_number(s)
      type = unpack_string(s, unpack_number(s))
      bytes = unpack_number(s)
      if s.length < bytes
        raise DataLengthError.new(s.length, bytes)
      end
      entry = Entry.new
      unpack_attributes(entry, type, s.slice!(0, bytes))
      return {
        "id" => id,
        "parent_id" => parent_id,
        "type" => type,
        "entry" => entry,
      }
    end

    def unpack_attributes(entry, type, s)
      template = ENTRY_ATTRIBUTE_TEMPLATES[type]
      if !template
        raise GPassFileError, _("invalid entry type: type=<%s>") % type
      end
      template.each do |a|
        attr = a.dup
        case attr
        when NumericAttribute
          attr.value = unpack_variable_number(s)
        when BooleanAttribute
          attr.value = unpack_boolean(s)
        when DateTimeAttribute
          attr.value = unpack_time(s)
        when TextAttribute
          attr.value = unpack_string(s, unpack_variable_number(s))
        end
        entry.add_attributes(attr)
      end
    end
    
    # s で指定したバイト列から 4 バイト取り出し、リトルエンディアンの数
    # 値として unpack した結果を返す。
    def unpack_number(s)
      if s.length < 4
        raise DataLengthError.new(s.length, 4)
      end
      return s.slice!(0, 4).unpack("V").first
    end

    # s で指定したバイト列から 8 ビット目が 0 のバイトを見つけるまで 1
    # バイトずつ取り出し、4 バイトのリトルエンディアンの数値として
    # unpack した結果を返す。
    def unpack_variable_number(s)
      n = 0
      base = 1
      i = 0
      while (t = s.slice!(0)) && i <= 5
        t = t.ord
        if t & 0x80 == 0
          n += base * t
          break
        else
          n += base * (t & 0x7f)
          base *= 0x80
        end
        i += 1
      end
      return [n].pack("V").unpack("I").first
    end

    # s で指定したバイト列から n で指定した長さを取り出し、それを文字列
    # として返す。
    def unpack_string(s, n)
      if s.length < n
        raise DataLengthError.new(s.length, n)
      end
      return s.slice!(0, n).force_encoding("utf-8")
    end

    # s で指定したバイト列から unpack_variable_number を使用して数値を
    # 取り出す。それを time_t の値として扱い、DateTimeオブジェクトを返す。
    def unpack_time(s)
      return Time.at(unpack_variable_number(s)).to_datetime
    end

    # s で指定したバイト列から unpack_variable_number を使用して数値を
    # 取り出す。それが 0 であれば false を、そうでなければ true を返す。
    def unpack_boolean(s)
      return unpack_variable_number(s) != 0
    end

    # GPass のファイルの処理中に発生したエラーを表現する例外クラス。
    class GPassFileError < ApplicationError
    end
  end
end
