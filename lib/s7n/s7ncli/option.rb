# -*- coding: utf-8 -*-

require "gettext"
require "optparse"

module S7n
  class S7nCli
    # Option クラスとそれを継承したクラスは Ximapd プロジェクトからコピー
    # しています。
    # * http://projects.netlab.jp/svn/ximapd/
    class Option
      include GetText
      
      def initialize(*args)
        case args.length
        when 2
          @name, @description = *args
          @arg_name = nil
        when 3
          @short_name, @name, @description = *args
        when 4
          @short_name, @name, @arg_name, @description = *args
        else
          msg = _("wrong # of arguments (%d for 2)") % args.length
          raise ArgumentError, msg
        end
      end

      def opt_name
        return @name.tr("_", "-")
      end

      def arg_name
        if @arg_name.nil?
          @arg_name = @name.slice(/[a-z]*\z/ni).upcase
        end
        return @arg_name
      end
    end

    class BoolOption < Option
      def define(opts, config)
        define_args = []
        if @short_name
          define_args << ("-" + @short_name)
        end
        define_args << ("--[no-]" + opt_name)
        define_args << @description
        opts.define(*define_args) do |arg|
          config[@name] = arg
        end
      end
    end

    class IntOption < Option
      def define(opts, config)
        define_args = []
        if @short_name
          define_args << ("-" + @short_name)
        end
        define_args << ("--" + opt_name + "=" + arg_name)
        define_args << Integer
        define_args << @description
        opts.define(*define_args) do |arg|
          config[@name] = arg
        end
      end
    end

    class StringOption < Option
      def define(opts, config)
        define_args = []
        if @short_name
          define_args << ("-" + @short_name)
        end
        define_args << ("--" + opt_name + "=" + arg_name)
        define_args << @description
        opts.define(*define_args) do |arg|
          config[@name] = arg
        end
      end
    end

    class ArrayOption < Option
      def define(opts, config)
        define_args = []
        if @short_name
          define_args << ("-" + @short_name)
        end
        s = arg_name[0, 1]
        args = ("1".."3").collect { |i| s + i.to_s }.join(",")
        define_args << ("--" + opt_name + "=" + args)
        define_args << Array
        define_args << @description
        opts.define(*define_args) do |arg|
          config[@name] = arg
        end
      end
    end
  end
end
