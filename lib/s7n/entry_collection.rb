# -*- coding: utf-8 -*-

require "s7n/entry"

module S7n
  # 機密情報の集合を表現する。
  class EntryCollection
    # 機密情報の配列。
    attr_reader :entries

    def initialize
      @entries = []
      @max_id = 0
    end

    # 機密情報を追加する。
    def add_entries(*entries)
      [entries].flatten.each do |entry|
        @max_id += 1
        entry.id = @max_id
        @entries.push(entry)
      end
    end

    # 機密情報を削除し、削除した機密情報を返す。
    def delete_entries(*entries)
      entries = [entries].flatten
      deleted_entries = []
      @entries.delete_if { |entry|
        if entries.include?(entry)
          deleted_entries << entry
          true
        else
          false
        end
      }
      return deleted_entries
    end

    # other で指定した EntryCollection オブジェクトの entries をマージ
    # する。
    def merge(other)
      add_entries(other.entries)
    end

    # 指定した id にマッチする Entry オブジェクトを entries から探す。
    def find(id)
      return @entries.find { |entry| entry.id == id }
    end
  end
end
