# -*- coding: utf-8 -*-

require "s7n/s7ncli/command"

module S7n
  class S7nCli
    # 機密情報をインポートするコマンドを表現する。
    class EntryCollectionImportCommand < Command
      command("import",
              ["entry_collection:import",
               "entry_collection:read",
               "entry_collection:load",
               "read",
               "load"],
              _("Import the entry colleciton from file."),
              _("usage: import [PATH] [OPTIONS]"))
      
      def initialize(*args)
        super
        @config["type"] = "gpass"
        @config["path"] = "~/.gpass/passwords.gps"
        @options.push(StringOption.new("type", _("type")), 
                      StringOption.new("path", _("path")))
      end
      
      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["path"] = argv.shift
        end
        case config["type"]
        when "gpass"
          path = File.expand_path(config["path"])
          if !File.file?(path)
            raise NotExist.new(path)
          end
          puts(_("Import the entry collection in the GPass file: %s") % path)
          gpass_file = GPassFile.new
          begin
            msg = _("Enter the master passphrase for GPass(^D is cancel): ")
            passphrase = S7nCli.input_string_without_echo(msg)
            if passphrase
              ec = gpass_file.read(passphrase, path)
              # TODO: UNDO スタックにタグの追加と機密情報の追加の操作を積む。
              world.entry_collection.merge(ec)
              world.changed = true
              puts(_("Imported %d entries.") % ec.entries.length)
            else
              canceled
            end
          rescue InvalidPassphrase => e
            puts(e.message)
            retry
          end
        else
          raise ArgumentError, _("not supported type: %s") % config["type"]
        end
        return true
      end
    end
  end
end
