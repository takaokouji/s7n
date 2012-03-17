# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7/attribute"

module S7
  class BooleanAttributeTest < Test::Unit::TestCase
    def test_display_value__true
      attr = BooleanAttribute.new("value" => true)
      assert_equal(_("Yes"), attr.display_value)
    end

    def test_display_value__false
      attr = BooleanAttribute.new("value" => false)
      assert_equal(_("No"), attr.display_value)
    end

    def test_display_value__secret
      values = [true, false]
      values.each do |value|
        attr = BooleanAttribute.new("value" => value, "secret" => "true")
        assert_equal("*", attr.display_value)
      end
    end

    def test_display_value__機密情報は＊にする
      attr = BooleanAttribute.new("value" => true, "secret" => "true")
      assert_equal("*", attr.display_value)
    end
  end

  class DateTimeAttributeTest < Test::Unit::TestCase
    def test_display_value
      t = Time.mktime(2008, 10, 21, 18, 14, 30).to_datetime
      attr = DateTimeAttribute.new("value" => t)
      assert_equal("2008/10/21 18:14:30", attr.display_value)
    end

    def test_display_value__only_date
      t = Time.mktime(2008, 10, 21, 0, 0, 0).to_datetime
      attr = DateTimeAttribute.new("value" => t)
      assert_equal("2008/10/21", attr.display_value)
    end

    def test_display_value__secret
      attr = DateTimeAttribute.new("secret" => "true")
      assert_equal("*", attr.display_value)
    end
  end
end
