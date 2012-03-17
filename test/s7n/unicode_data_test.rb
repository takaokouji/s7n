# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7n/unicode_data"

module S7n
  class UnicodeDataTest < Test::Unit::TestCase
    include UnicodeData

    def test_s_east_asian_width
      # ASCII
      ("\u0020".."\u007D").each do |i|
        assert_equal(:N, UnicodeData.east_asian_width(i.chr), "character=<#{i}>")
      end
      assert_equal(:N, UnicodeData.east_asian_width("\u203E"), "character=<\u203E>")
      
      # 半角カナ
      ("\uFF61".."\uFF9F").each do |i|
        assert_equal(:H, UnicodeData.east_asian_width(i.chr), "character=<#{i}>")
      end

      # 上記以外
      ("あ".."ん").each do |i|
        assert_equal(:F, UnicodeData.east_asian_width(i.chr), "character=<#{i}>")
      end
    end
  end
end
