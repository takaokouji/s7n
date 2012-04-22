# -*- coding: utf-8 -*-

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "s7n/world"
require "tmpdir"

module S7n
  class WorldTest < Test::Unit::TestCase
    setup do
      @world = World.new
      @tmpdir = Dir.mktmpdir
      @world.base_dir = @tmpdir
      @world.master_key = "qwerty"
    end
    
    teardown do
      FileUtils.remove_entry_secure(@tmpdir)
    end
    
    context "save" do
      should "変更がない場合は何もしない" do
        @world.save
        assert_equal(false, File.file?(@world.secrets_path))
      end
      
      should "引数にtrueを指定すると強制的に保存する" do
        @world.save(true)
        assert_equal(true, File.file?(@world.secrets_path))
      end
    end

    context "start_logging" do
      should "s7n.logがあればそれを使う" do
        path = File.expand_path("s7n.log", @world.base_dir)
        FileUtils.touch(path)
        FileUtils.touch(File.expand_path("s7.log", @world.base_dir))
        proxy.mock(Logger).new(path)
        @world.start_logging
      end

      should "s7n.logがなくてs7.logがあればs7.logを使う" do
        path = File.expand_path("s7.log", @world.base_dir)
        FileUtils.touch(path)
        proxy.mock(Logger).new(path)
        @world.start_logging
      end

      should "s7n.logとs7.logが両方なければs7n.logを使う" do
        path = File.expand_path("s7n.log", @world.base_dir)
        proxy.mock(Logger).new(path)
        @world.start_logging
      end
    end
  end
end
