# -*- coding: utf-8 -*-

require "s7n/s7ncli/command"
require "open3"

module S7n
  class S7nCli
    # 機密情報の属性のうち、指定したものの値をクリップボードにコピーするコ
    # マンドを表現する。
    class AttributeCopyCommand < Command
      command("copy",
              ["attribute:copy",
               "c"],
              _("Copy the attribute value to the clipboard."),
              _("usage: copy [ID] [ATTRIBUTE NAME] [OPTIONS]"))
      
      def initialize(*args)
        super
        copy_commands = ["/usr/bin/pbcopy", "/usr/bin/xclip"]
        copy_commands.each do |cmd|
          if File.executable?(cmd)
            @config["copy_command"] = cmd
          end
        end
        @config["inclement_rate"] = true
        @options.push(IntOption.new("i", "id", "ID", _("Entry ID.")),
                      StringOption.new("n", "name", _("Attribute name.")),
                      BoolOption.new("inclement_rate",
                                     _("Inclement the entry's rate after copied.")),
                      BoolOption.new("l", "lock",
                                     _("Lock screen after copied.")),
                      StringOption.new("copy_command", _("Copy command.")))
      end

      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["id"] = argv.shift.to_i
        end
        if argv.length > 0
          config["name"] = argv.shift
        else
          config["name"] = "password"
        end
        if config["id"].nil? || config["name"].nil?
          puts(_("Too few arguments."))
          help
          return true
        end
        puts(_("Copy the attribute value to the clipboard."))
        entry = world.entry_collection.find(config["id"])
        if entry.nil?
          raise NoSuchEntry.new("id" => config["id"])
        end
        attr = entry.get_attribute(config["name"])
        if attr.nil?
          raise NoSuchAttribute.new("id" => config["id"],
                                    "name" => config["name"])
        end
        copy_command = @config["copy_command"]
        res, status = Open3.capture2(copy_command,
                                     stdin_data: attr.value.to_s,
                                     binmode: true)
        if status != 0
          raise CommandFailed.new(copy_command, status)
        end
        if config["inclement_rate"]
          # TODO: undo スタックに操作を追加する。
          entry.rate += 1
          puts(_("Changed rate to %d.") % entry.rate)
          world.changed = true
        end
        if config["lock"]
          sleep(1)
          lock_command = Command.create_instance("lock", world)
          return lock_command.run([])
        end
        return true
      end
    end
  end
end
