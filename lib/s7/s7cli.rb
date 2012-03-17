# -*- coding: utf-8 -*-

require "optparse"
require "readline"
require "gettext"
require "fileutils"
require "s7/s7cli/option"
require "s7/s7cli/command"
command_pattern =
  File.expand_path("s7cli/*_command.rb", File.dirname(__FILE__))
Dir.glob(command_pattern).each do |path|
  require path.gsub(/\.rb\z/, "")
end

# s7 のコマンドラインインタフェースを表現する。
module S7
  class S7Cli
    include GetText

    # 最初に実行するメソッド。
    def self.run(argv)
      obj = S7Cli.new
      obj.parse_command_line_argument(argv)
      obj.run
    end

    # prompt に指定した文字列を表示後、Readline ライブラリを利用してユー
    # ザからの入力を得る。
    def self.input_string(prompt = "", add_history = true)
      input = Readline.readline(prompt, add_history)
      input.force_encoding("utf-8") if input
      return input
    end

    # prompt に指定した文字列を表示後、エコーバックせずにユーザからの入
    # 力を得る。パスフレーズの入力を想定。
    def self.input_string_without_echo(prompt = "")
      print(prompt) if prompt.length > 0
      STDOUT.flush
      Utils.execute("stty -echo")
      begin
        input = STDIN.gets
      ensure
        Utils.execute("stty echo")
        puts("")
      end
      if input
        input.chomp!
        input.force_encoding("utf-8")
      end
      return input
    end

    # prompt に指定した文字列を表示後、ユーザからの入力を得る。
    # それがyes、y、true、t、okのいずれかであれば true を返し、
    # そうでなければ false を返す。大小文字は区別しない。
    # ^D などにより何も入力しない場合、defualt で指定した真偽値を返す。
    def self.input_boolean(prompt = "", default = false)
      if input = Readline.readline(prompt, false)
        input.strip!
        if input.empty?
          return default
        end
        input.force_encoding("utf-8")
        if /\Ay|yes|t|true|ok\z/i =~ input
          return true
        else
          return false
        end
      else
        return default
      end
    end

    # World クラスのインスタンス。
    attr_accessor :world

    def initialize
      @world = World.new
    end

    # コマンドラインオプションを解析する。
    def parse_command_line_argument(argv)
      option_parser = OptionParser.new { |opts|
        opts.banner = _("usage: s7cli [options]")
        opts.separator("")
        opts.separator(_("options:"))
        opts.on("-d", "--base-dir=DIR",
                _("Specify the base directory. Default is '%s'.") % world.base_dir) do |dir|
          world.base_dir = dir
        end
        opts.on("-v", "--version", _("Show version.")) do
          puts(_("s7cli, version %s") % S7::VERSION)
          exit(0)
        end
        opts.on("-h", "--help",
                _("Show help and exit.")) do
          puts(opts)
          exit(0)
        end
      }
      option_parser.parse(argv)
    end
  
    # メインの処理を行う。
    def run
      if File.exist?(world.base_dir)
        if !File.directory?(world.base_dir)
          Utils::shred_string(master_key)
          raise InvalidPath.new(world.base_dir)
        end
        world.start_logging
        begin
          master_key =
            S7Cli.input_string_without_echo(_("Enter the master key for s7: "))
          if master_key.nil?
            exit(1)
          end
          world.load(S7File.read(world.secrets_path, master_key))
          world.master_key = master_key
        rescue InvalidPassphrase => e
          puts(e.message)
          retry
        end
      else
        master_key =
          S7Cli.input_string_without_echo(_("Enter the master key for s7: "))
        if master_key.nil?
          exit(1)
        end
        confirmation =
          S7Cli.input_string_without_echo(_("Comfirm the master key for s7: "))
        if master_key != confirmation
          Utils::shred_string(master_key)
          Utils::shred_string(confirmation) if !confirmation.nil?
          raise InvalidPassphrase
        end
        world.master_key = master_key
        FileUtils.mkdir_p(world.base_dir)
        FileUtils.chmod(0700, world.base_dir)
        world.start_logging
        world.logger.info(_("created base directory: %s") % world.base_dir)
        world.save(true)
      end
      world.lock
      begin
        path = File.join(world.base_dir, "s7cli")
        if File.file?(path)
          begin
            hash = YAML.load(S7File.read(path, world.master_key))
            hash["history"].each_line do |line|
              Readline::HISTORY.push(line.chomp)
            end
          rescue
            puts(_("could not read: %s") % path)
            raise
          end
        end
        loop do
          begin
            prompt = "%ss7> " % (world.changed ? "*" : "")
            input = S7Cli.input_string(prompt, true)
            if !input
              puts("")
              break
            end
            name, argv = *Command.split_name_and_argv(input)
            if !name
              next
            end
            command = Command.create_instance(name, world)
            if command
              if !command.run(argv)
                break
              end
            else
              raise ApplicationError, _("Unknown command: %s") % name
            end
          rescue Interrupt
            puts("")
            retry
          rescue ApplicationError
            puts($!)
          rescue => e
            puts(e.message)
            puts("----- back trace -----")
            e.backtrace.each do |line|
              puts("  #{line}")
            end
          end
        end
      ensure
        begin
          world.save
          begin
            path = File.join(world.base_dir, "s7cli")
            # TODO: history の上限を設ける。
            hash = {
              "history" => Readline::HISTORY.to_a.join("\n"),
            }
            S7File.write(path, world.master_key,
                         world.configuration.cipher_type, hash.to_yaml)
          rescue
            puts(_("could not write: %s") % path)
            puts($!)
          end
        ensure
          world.unlock
        end
      end
    end
  end
end
