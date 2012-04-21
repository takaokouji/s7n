# -*- coding: utf-8 -*-

require_relative "../test_helper"
require "s7n/entry_collection"

module S7n
  class EntryCollectionTest < Test::Unit::TestCase
    setup do
      @entry_collection = EntryCollection.new
    end

    １０個の機密情報を登録済み = lambda {
      @entries = (1..10).map { |i|
        Entry.new(id: i, name: "no#{i}")
      }
      @entry_collection.add_entries(@entries)
    }

    context "add_entries" do
      should "1つの機密情報を追加する" do
        entry = Entry.new(id: 1, name: "no1")
        assert(@entry_collection.entries.empty?)
        @entry_collection.add_entries(entry)
        assert_equal([entry], @entry_collection.entries)
      end
      
      should "複数の機密情報を追加する" do
        entries = [Entry.new(id: 1, name: "no1"), Entry.new(id: 2, name: "no2")]
        assert(@entry_collection.entries.empty?)
        @entry_collection.add_entries(entries)
        assert_equal(entries, @entry_collection.entries)
      end
    end
    
    context "delete_entries" do
      should "1つの機密情報を削除し、削除した機密情報を返す", before: １０個の機密情報を登録済み do
        entry = @entries.first
        assert_equal([entry], @entry_collection.delete_entries(entry))
        assert_equal(@entries[1..-1], @entry_collection.entries)
      end

      should "複数の機密情報を削除し、削除した機密情報を返す", before: １０個の機密情報を登録済み do
        assert_equal(@entries[0..4], @entry_collection.delete_entries(@entries[0..4]))
        assert_equal(@entries[5...10], @entry_collection.entries)
      end
    end
  end
end
