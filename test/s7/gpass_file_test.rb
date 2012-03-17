# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7/gpass_file"
require "time"

module S7
  class GPassFileTest < Test::Unit::TestCase
    # パスフレーズが不正な場合、 InvalidPassphrase 例外が発生する。
    def test_read__invalid_passphrase
      invalid_passphrases = ["", "1234", "qwert", "qwertyu", "QWERTY"]
      file = GPassFile.new
      invalid_passphrases.each do |s|
        assert_raises(InvalidPassphrase) do
          file.read(s, gpass_file_path("empty"))
        end
      end
    end

    # 機密情報がひとつもないファイルを読み込む。
    def test_read__empty
      file = GPassFile.new
      res = file.read("qwerty", gpass_file_path("empty"))
      assert(res.entries.empty?)
    end

    # 機密情報がひとつのファイルを読み込む。
    def test_read__one_entry
      file = GPassFile.new
      res = file.read("qwerty", gpass_file_path("one_entry"))
      entry = res.entries.first
      assert_equal(1, entry.id)
      assert_equal("entry1", entry.name)
      assert_equal("This is entry 1.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:17:06").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:17:06").to_datetime, entry.updated_at)
      assert_equal("foo", entry.username)
      assert_equal("1234", entry.password)
      assert_equal(true, entry.expiration)
      assert_equal(Time.parse("2009-10-05 09:00:00").to_datetime, entry.expire_at)
      assert_equal([], entry.tags)
      assert_equal(1, res.entries.length)
    end

    # 機密情報が 3 つのファイルを読み込む。
    def test_read__three_entry
      file = GPassFile.new
      res = file.read("qwerty", gpass_file_path("three_entries"))

      entry = res.entries[0]
      assert_equal(1, entry.id)
      assert_equal("entry1", entry.name)
      assert_equal("This is entry 1.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:17:06").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:17:06").to_datetime, entry.updated_at)
      assert_equal("foo", entry.username)
      assert_equal("1234", entry.password)
      assert_equal(true, entry.expiration)
      assert_equal(Time.parse("2009-10-05 09:00:00").to_datetime, entry.expire_at)
      assert_equal("example.com", entry.hostname)
      assert_equal([], entry.tags)

      entry = res.entries[1]
      assert_equal(2, entry.id)
      assert_equal("entry2", entry.name)
      assert_equal("This is entry 2.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:18:41").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:18:41").to_datetime, entry.updated_at)
      assert_equal("bar", entry.username)
      assert_equal("5678", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal([], entry.tags)

      entry = res.entries[2]
      assert_equal(3, entry.id)
      assert_equal("entry3", entry.name)
      assert_equal("This is entry 3.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:19:15").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:19:15").to_datetime, entry.updated_at)
      assert_equal("baz", entry.username)
      assert_equal("9876", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal([], entry.tags)

      assert_equal(3, res.entries.length)
    end

    # フォルダを含むファイルを読み込む。
    def test_read__with_folders
      file = GPassFile.new
      res = file.read("qwerty", gpass_file_path("with_folders"))

      entry = res.entries[0]
      assert_equal(1, entry.id)
      assert_equal("entry1-1", entry.name)
      assert_equal("This is entry 1-1.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:17:06").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:20:58").to_datetime, entry.updated_at)
      assert_equal("foo", entry.username)
      assert_equal("1234", entry.password)
      assert_equal(true, entry.expiration)
      assert_equal(Time.parse("2009-10-05 09:00:00").to_datetime, entry.expire_at)
      assert_equal("example.com", entry.hostname)
      assert_equal(["folder1"], entry.tags)

      entry = res.entries[1]
      assert_equal(2, entry.id)
      assert_equal("entry1-2", entry.name)
      assert_equal("This is entry 1-2.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:20:33").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:20:33").to_datetime, entry.updated_at)
      assert_equal("", entry.username)
      assert_equal("", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal(["folder1"], entry.tags)

      entry = res.entries[2]
      assert_equal(3, entry.id)
      assert_equal("entry2-1", entry.name)
      assert_equal("This is entry 2-1.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:18:41").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:21:33").to_datetime, entry.updated_at)
      assert_equal("bar", entry.username)
      assert_equal("5678", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal(["folder2"], entry.tags)

      entry = res.entries[3]
      assert_equal(4, entry.id)
      assert_equal("entry 2-2-1", entry.name)
      assert_equal("This is entry 2-2-1.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:22:00").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:22:00").to_datetime, entry.updated_at)
      assert_equal("", entry.username)
      assert_equal("", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal(["folder2", "folder2-2"], entry.tags)

      entry = res.entries[4]
      assert_equal(5, entry.id)
      assert_equal("entry3", entry.name)
      assert_equal("This is entry 3.", entry.description)
      assert_equal(Time.parse("2008-10-05 00:19:15").to_datetime, entry.created_at)
      assert_equal(Time.parse("2008-10-05 00:19:15").to_datetime, entry.updated_at)
      assert_equal("baz", entry.username)
      assert_equal("9876", entry.password)
      assert_equal(false, entry.expiration)
      assert_equal("", entry.hostname)
      assert_equal([], entry.tags)

      assert_equal(5, res.entries.length)
    end
    
    private
    
    # 本テストで使用する GPass のファイル名を取得する。
    # name には gpass_file_test/passwords.gps. より後の部分を指定する。
    def gpass_file_path(name)
      return File.join(File.dirname(__FILE__),
                       "gpass_file_test",
                       "passwords.gps." + name)
    end
  end
end
