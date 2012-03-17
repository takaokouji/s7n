# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7n/world"
require "tmpdir"

module S7n
  class WorldTest < Test::Unit::TestCase
    def test_save__not_changed
      world = World.new
      tmpdir = Dir.mktmpdir
      begin
        world.base_dir = tmpdir
        world.master_key = "qwerty"
        world.save
        assert_equal(false, File.file?(world.secrets_path))
      ensure
        FileUtils.remove_entry_secure(tmpdir)
      end
    end

    def test_save__force
      world = World.new
      tmpdir = Dir.mktmpdir
      begin
        world.base_dir = tmpdir
        world.master_key = "qwerty"
        world.save(true)
        assert_equal(true, File.file?(world.secrets_path))
      ensure
        FileUtils.remove_entry_secure(tmpdir)
      end
    end
  end
end
