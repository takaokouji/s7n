# -*- coding: utf-8 -*-

require "gettext"

module S7n
  class S7nCli
    # コマンドを表現する。
    class Command
      include GetText

      # オプションの配列。
      attr_reader :options

      # 設定。
      attr_reader :config

      # World オブジェクト。
      attr_reader :world

      @@command_classes = {}
      
      class << self
        # s で指定した文字列をコマンド名とオプションに分割する。
        def split_name_and_argv(s)
          s = s.strip
          name = s.slice!(/\A\w+/)
          argv = s.split
          return name, argv
        end
        
        def create_instance(name, world)
          klass = @@command_classes[name]
          if klass
            return klass.new(world)
          else
            return nil
          end
        end
        
        private
      
        def command(name, aliases, description, usage)
          @@command_classes[name] = self
          self.const_set("NAME", name)
          aliases.each do |s|
            @@command_classes[s] = self
          end
          self.const_set("ALIASES", aliases)
          self.const_set("DESCRIPTION", description)
          self.const_set("USAGE", usage)
        end
      end

      def initialize(world)
        @world = world
        @config = {}
        @options = []
      end

      # コマンド名を取得する。
      def name
        return self.class.const_get("NAME")
      end

      # 別名の配列を取得する。
      def aliases
        return self.class.const_get("ALIASES")
      end

      # 概要を取得する。
      def description
        return self.class.const_get("DESCRIPTION")
      end

      # 使用例を取得する。
      def usage
        return self.class.const_get("USAGE")
      end

      # コマンドラインオプションを解析するための OptionParser オブジェ
      # クトを取得する。
      def option_parser
        return OptionParser.new { |opts|
          opts.banner = [
                         "#{name} (#{aliases.join(",")}): #{description}",
                         usage,
                        ].join("\n")
          if options && options.length > 0
            opts.separator("")
            opts.separator("Valid options:")
            for option in options
              option.define(opts, config)
            end
          end
        }
      end

      # 使用方法を示す文字列を返す。
      def help
        puts(option_parser)
        return 
      end

      private

      # キャンセルした旨を出力し、true を返す。
      # Command オブジェクトの run メソッドで return canceled という使
      # い方を想定している。
      def canceled
        puts("\n" + Canceled::MESSAGE)
        return true
      end
    end

    # プログラムを終了するコマンドを表現する。
    class HelpCommand < Command
      command("help",
              ["usage", "h"],
              _("Describe the commands."),
              _("usage: help [COMMAND]"))
      
      def run(argv)
        if argv.length > 0
          command_name = argv.shift
          command = Command.create_instance(command_name, world)
          if command
            command.help
          else
            puts(_("Unknown command: %s") % command_name)
          end
        else
          puts(_("Type 'help <command>' for help on a specific command."))
          puts("")
          puts(_("Available commands:"))
          command_classes = @@command_classes.values.uniq.sort_by { |klass|
            klass.const_get("NAME")
          }
          command_classes.each do |klass|
            s = "  #{klass.const_get("NAME")}"
            aliases = klass.const_get("ALIASES")
            if aliases.length > 0
              s << " (#{aliases.sort_by { |s| s.length}.first})"
            end
            puts(s)
          end
        end
        return true
      end
    end

    # 現在の状態を保存するコマンドを表現する。
    class SaveCommand < Command
      command("save", [], _("Save."), _("usage: save"))

      def initialize(*args)
        super
        @options.push(BoolOption.new("f", "force", _("Force.")))
      end

      def run(argv)
        option_parser.parse!(argv)
        world.save(config["force"])
        puts(_("Saved."))
        return true
      end
    end

    # スクリーンロックし、マスターキーを入力するまでは操作できないよう
    # にするコマンドを表現する。
    class LockCommand < Command
      command("lock", [], _("Lock screen after saved."), _("usage: lock"))

      def run(argv)
        system("clear")
        puts(_("Locked screen."))
        world.save
        prompt = _("Enter the master key for s7n: ")
        begin
          input = S7Cli.input_string_without_echo(prompt)
          if input != world.master_key
            raise InvalidPassphrase
          end
          puts(_("Unlocked."))
          return true
        rescue Interrupt
        rescue ApplicationError => e
          puts($!.message + _("Try again."))
          retry
        rescue Exception => e
          puts(e.message)
          if world.debug
            puts(_("----- back trace -----"))
            e.backtrace.each do |line|
              puts("  #{line}")
            end
          end
        end
        puts(_("Quit."))
        return false
      end
    end
    
    # プログラムを終了するコマンドを表現する。
    class QuitCommand < Command
      command("quit",
              ["exit", "q"],
              _("Quit."),
              _("usage: quit"))

      def run(argv)
        return false
      end
    end
  end
end
