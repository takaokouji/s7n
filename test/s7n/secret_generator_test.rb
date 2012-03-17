# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7n/secret_generator"

module S7n
  class SecretGeneratorTest < Test::Unit::TestCase
    def test_s_generate__length
      (1..1000).each do |length|
        value = SecretGenerator.generate(length: length)
        assert_equal(length, value.length)
      end
    end

    def test_s_generate__characters
      value = SecretGenerator.generate(length: 100,
                                       characters: [:upper_alphabet])
      assert_equal("", value.delete("A-Z"))

      value = SecretGenerator.generate(length: 100,
                                       characters: [:lower_alphabet])
      assert_equal("", value.delete("a-z"))

      value = SecretGenerator.generate(length: 100,
                                       characters: [:number])
      assert_equal("", value.delete("0-9"))
    end
  end
end
