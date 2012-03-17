# -*- coding: utf-8 -*-

require "logger"
require "gettext"
require "fileutils"
require "yaml"
require "s7n/utils"
require "s7n/entry_collection"
require "s7n/undo_stack"
require "s7n/configuration"
require "s7n/s7n_file"

module S7n
  # アプリケーション全体を表現する。
  class World
    include GetText
    
    # 設定や機密情報などを格納するディレクトリ。
    attr_accessor :base_dir

    # Logger のインスタンス。
    attr_accessor :logger

    # マスターキー。
    attr_accessor :master_key

    # 機密情報の集合。
    attr_reader :entry_collection

    # UndoStack オブジェクト。
    attr_reader :undo_stack

    # Configuration オブジェクト。
    attr_reader :configuration

    # 変更があるかどうか。
    attr_accessor :changed

    # デバッグモードかどうか。
    attr_accessor :debug

    def initialize
      @base_dir = File.join(Utils::home_dir, ".s7")
      @logger = Logger.new(STDERR)
      @entry_collection = EntryCollection.new
      @undo_stack = UndoStack.new
      @configuration = Configuration.new(self)
      @changed = false
      @debug = false
    end
    
    # 2 重起動を防止するためにロックするためのファイルのパスを取得する。
    def lock_path
      return File.join(base_dir, "lock")
    end
    
    # 機密情報を格納するファイルのパスを取得する。
    def secrets_path
      return File.join(base_dir, "secrets")
    end

    # 設定を格納するファイルのパスを取得する。
    def configuration_path
      return File.join(base_dir, "configuration")
    end
    
    # ログの記録を開始する。
    def start_logging
      log_path = File.join(base_dir, "s7n.log")
      self.logger = Logger.new(log_path)
      logger.level = Logger::DEBUG
    end

    # 2 重起動を防止するため、lock ファイルを作成する。
    # すでに s7 を起動していた場合、ApplicationError 例外を発生させる。
    def lock
      if File.exist?(lock_path)
        pid = File.read(lock_path).to_i
        begin
          Process.kill(0, pid)
          raise ApplicationError, _("running other s7n: pid=<%d>") % pid
        rescue Errno::ENOENT, Errno::ESRCH
        end
      end
      File.open(lock_path, "w") do |f|
        f.flock(File::LOCK_EX)
        f.write(Process.pid)
      end
    end

    # lock ファイルを削除する。
    def unlock
      if File.exist?(lock_path)
        pid = File.read(lock_path).to_i
        if pid == Process.pid
          FileUtils.rm(lock_path)
        else
          raise ApplicationError, _("running other s7n: pid=<%d>") % pid
        end
      end
    end
    
    def dump
      hash = {}
      hash["entries"] = entry_collection.entries.collect { |entry|
        {
          "attributes" => entry.attributes.collect { |attr|
            {
              "type" => attr.type,
              "name" => attr.name,
              "value" => attr.value,
              "secret" => attr.secret?,
              "editabled" => attr.editable?,
              "protected" => attr.protected?,
            }
          },
          "tags" => entry.tags,
        }
      }
      return hash.to_yaml
    end

    def load(data)
      hash = YAML.load(data)
      hash["entries"].each do |entry_hash|
        entry = Entry.new
        attributes = entry_hash["attributes"].collect { |attr_hash|
          type = attr_hash["type"]
          attr_names = ["name", "value", "secret", "editabled", "protected"]
          Attribute.create_instance(type, 
                                    attr_hash.select { |key, value|
                                      attr_names.include?(key)
                                    })
        }
        entry.add_attributes(attributes)
        entry.tags.push(*entry_hash["tags"])
        entry_collection.add_entries(entry)
      end
    end
    
    # 情報をファイルに書き出す。
    # すでに secrets ファイルが存在してれば、.bak というサフィックスを
    # 追加してバックアップを取る。
    def save(force = false)
      if force || @changed
        if File.exist?(secrets_path)
          FileUtils.cp(secrets_path, secrets_path + ".bak")
        end
        S7nFile.write(secrets_path,
                      master_key,
                      configuration.cipher_type,
                      dump)
        configuration.save(configuration_path)
        @changed = false
      end
    end
  end
end
