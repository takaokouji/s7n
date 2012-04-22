# -*- coding: utf-8 -*-

require "s7n/s7ncli/command"
require "s7n/secret_generator"
require "s7n/unicode_data"

module S7n
  class S7nCli
    # 機密情報の操作をするコマンドで使用するメソッド群。
    module EntryCommandUtils
      include GetText
      
      EDITING_USAGE =
        ["-----",
         _("<n>,e<n>:edit attribute a:add attribute d<n>:delete attribute"),
         _("t:edit tags s:save")].join("\n")
      
      # ユーザに属性名を入力するように促し、入力された値を返す。
      def input_attribute_name(default = nil)
        names = (@entry.attributes.collect(&:name) +
                 @attributes.collect(&:name)).uniq
        if default
          s = " (#{default})"
        else
          s = ""
        end
        prompt = _("Attribute name%s: ") % s
        begin
          if input = S7nCli.input_string(prompt)
            input.strip!
            if input.empty?
              input = default
            elsif names.include?(input)
              raise ApplicationError, _("Already exist: %s") % input
            end
          end
          return input
        rescue ApplicationError => e
          puts("")
          puts(e.message)
          retry
        end
      end
      
      # ユーザに属性の値を入力するように促し、入力された値を返す。
      # ^D を入力されて、なおかつ protected が false の場合、nil を返す。
      def input_value(value, secret, protected)
        if value.length > 0
          current = _(" (%s)") % value
        else
          current = ""
        end
        prompt = _("Value%s: ") % current
        begin
          if secret
            if input = S7nCli.input_string_without_echo(prompt)
              confirmation =
                S7nCli.input_string_without_echo(_("Comfirm value: "))
              if input != confirmation
                raise ApplicationError, _("Mismatched.")
              end
            end
          else
            input = S7nCli.input_string(prompt)
          end
          if input
            input.strip! 
            if input.empty? && value
              input = value
            end
          end
          if protected && (input.nil? || input.empty?)
            raise ApplicationError, _("The value is empty.")
          end
        rescue ApplicationError => e
          puts("")
          puts(e.message + _("Try again."))
          retry
        end
        return input
      end

      # ユーザにタグの入力を促す。入力内容を解析し、タグ名の配列を返す。
      # ^D を入力された場合、nil を返す。
      def input_tags(tags)
        if tags.length > 0
          current = " (" + tags.join(", ") + ")"
        else
          current = ""
        end
        prompt = _("Edit tags%s: ") % current
        if input = S7nCli.input_string(prompt)
          return input.split(",").collect { |t| t.strip }
        else
          return nil
        end
      end

      # ユーザに機密情報かどうかの入力を促す。
      def input_secret(default)
        prompt = _("Is this a secret? (%s): ") % (default ? "yes" : "no")
        return S7nCli.input_boolean(prompt, default)
      end

      # ユーザに属性の型の入力を促す。
      def input_attribute_type
        prompt = _("Attribute type: ")
        types = Attribute.types
        Readline.completion_proc = Proc.new { |text|
          begin
            s = Readline.line_buffer.lstrip
          rescue NotImplementedError, NoMethodError
            s = text
          end
          types.select { |type|
            type =~ /\A#{s}/
          }
        }
        begin
          if input = S7nCli.input_string(prompt)
            input.strip!
            if !types.include?(input)
              raise ApplicationError, _("Unknown type: %s") % input
            end
          end
          return input
        rescue ApplicationError => e
          puts(e.message)
          puts(_("Try again."))
          retry
        ensure
          begin
            Readline.completion_proc = nil
          rescue ArgumentError
          end
        end
      end

      # ユーザにコマンドの入力を促す。終了コマンドを入力するまで繰り返す。
      def command_loop
        begin
          loop do
            begin
              puts("-----")
              @attributes.each.with_index do |attr, i|
                value = attr.display_value
                printf("  %2d) %s: %s\n", i, _(attr.name), value)
              end
              printf("   t) %s: %s\n", _("tags"), @tags.join(", "))
              puts("-----")
              prompt = _("Command (h:help, s:save, ^C:cancel): ")
              input = S7nCli.input_string(prompt)
              if input.nil?
                raise Interrupt
              end
              begin
                if !dispatch_command(input)
                  break
                end
              rescue Interrupt
                raise Canceled
              end
            rescue ApplicationError => e
              puts(e.message)
            end
          end
        rescue Interrupt
          canceled
        end
      end

      # ユーザからの入力 input を解析し、適切なコマンドを処理する。
      def dispatch_command(input)
        case input
        when /\A\s*(\d+)\z/, /\Ae\s*(\d+)\z/
          index = $1.to_i
          attr = @attributes[index]
          if attr.nil?
            raise ApplicationError, _("Invalid index: %d") % index
          end
          puts(_("Edit attribute: %s") % _(attr.name))
          if attr.protected?
            name = attr.name
            secret = attr.secret?
          else
            name = input_attribute_name(attr.name)
            if name.nil?
              raise Canceled
            end
            secret = input_secret(attr.secret?)
          end
          if secret
            prompt = _("Generate value? (no): ")
            if S7nCli.input_boolean(prompt, false)
              prompt = _("Length (8): ")
              length = S7nCli.input_string(prompt).to_i
              if length <= 0
                length = 8
              end
              value = SecretGenerator.generate(length: length,
                                               characters: [:alphabet, :number])
            end
          end
          if value.nil?
            value =
              input_value(attr.display_value(secret), secret, attr.protected?)
          end
          if value.nil?
            raise Canceled
          end
          attr.name = name
          attr.secret = secret
          attr.value = value
          puts(_("Updated '%s'.") % _(attr.name))
        when "a"
          puts(_("Add attribute."))
          name = input_attribute_name
          if name.nil?
            raise Canceled
          end
          type = input_attribute_type
          if type.nil?
            raise Canceled
          end
          secret = input_secret(false)
          if secret
            prompt = _("Generate value? (no): ")
            if S7nCli.input_boolean(prompt, false)
              # TODO: pwgen コマンドを呼び出す生成機を選択できるようにする。
              prompt = _("Length (8): ")
              length = S7nCli.input_string(prompt).to_i
              if length <= 0
                length = 8
              end
              # TODO: 文字種も選べるようにする。
              value = SecretGenerator.generate(length: length)
            end
          end
          if value.nil?
            value = input_value("", secret, false)
          end
          if value.nil?
            raise Canceled
          end
          options = {
            "name" => name,
            "secret" => secret,
            "value" => value,
          }
          attr = Attribute.create_instance(type, options)
          @attributes.push(attr)
          puts(_("Added attribute: '%s'") % _(attr.name))
        when /\Ad\s*(\d+)\z/
          index = $1.to_i
          attr = @attributes[index]
          if attr.nil?
            raise ApplicationError, _("Invalid index: %d") % index
          end
          if attr.protected?
            msg = _("Can't delete attribute: %s") % _(attr.name)
            raise ApplicationError, msg
          end
          prompt = _("Delete attribute '%s'? (no): ") % _(attr.name)
          if !S7nCli.input_boolean(prompt)
            raise Canceled
          end
          @attributes.delete(attr)
          puts(_("Deleted attribute: '%s'") % _(attr.name))
        when "t"
          if input = input_tags(@tags)
            @tags = input
          else
            raise Canceled
          end
          puts(_("Updated tags."))
        when "s"
          save
          world.changed = true
          puts(_("Saved: %d") % @entry.id)
          return false
        when "h"
          puts(EDITING_USAGE)
        else
          raise ApplicationError, _("Unknown command: %s") % input
        end
        return true
      end
      
      # 機密情報に対する属性とタグの変更を反映させる。
      def apply_entry_changes
        @entry.tags.replace(@tags)
        d = @entry.attributes.collect(&:name) - @attributes.collect(&:name)
        if d.length > 0
          @entry.attributes.delete_if { |attr|
            attr.editable? && d.include?(attr.name)
          }
        end
        @entry.add_attributes(@attributes)
      end

      # entry に指定した機密情報を表示する。
      def display_entry(entry)
        attr_names = entry.attributes.collect { |attr|
          _(attr.name)
        }
        n = attr_names.collect(&:length).max
        entry.attributes.each do |attr|
          secret = attr.secret? && !config["show_secret"]
          value = attr.display_value(secret)
          puts("%-#{n}s: %s" % [_(attr.name), value])
        end
        puts("%-#{n}s: %s" % [_("tag"), entry.tags.join(", ")])
      end
    end

    # 機密情報を追加するコマンドを表現する。
    class EntryAddCommand < Command
      include EntryCommandUtils

      command("add",
              ["entry:add",
               "entry:new",
               "entry:create",
               "new",
               "create",
               "a"],
              _("Add the entry."),
              _("usage: add [NAME] [TAGS] [OPTIONS]"))
      
      def initialize(*args)
        super
        @config["tags"] = []
        @config["attributes"] = []
        @options.push(StringOption.new("n", "name", _("Name.")),
                      ArrayOption.new("t", "tags", _("Tags.")),
                      IntOption.new("c", "copy", "ID",
                                    _("Entry ID that is copied.")))
      end

      # 機密情報を追加する。
      def save
        apply_entry_changes
        # TODO: undo スタックに操作を追加する。
        world.entry_collection.add_entries(@entry)
      end

      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["name"] = argv.shift
        end
        if argv.length > 0
          config["tags"].push(*argv.shift.split(","))
        end
        if config["copy"]
          from_entry = world.entry_collection.find(config["copy"])
          if !from_entry
            raise NoSuchEntry.new("id" => config["copy"])
          end
        end
        puts(_("Add the entry."))
        @entry = Entry.new
        if from_entry
          @entry.add_attributes(from_entry.duplicate_attributes)
        end
        @attributes = @entry.attributes.select { |attr|
          attr.editable?
        }
        attr = @entry.get_attribute("name")
        if config["name"]
          attr.value = config["name"]
        end
        if attr.value.to_s.empty?
          puts(_("Edit attribute: %s") % _(attr.name))
          attr.value =
            input_value(attr.display_value, attr.secret?, attr.protected?)
        end
        if config["tags"].length > 0
          @tags = config["tags"]
        else
          @tags = @entry.tags
        end
        if @tags.empty?
          @tags = input_tags(@tags) || []
        end
        command_loop
        return true
      end
    end

    # 機密情報を追加するコマンドを表現する。
    class EntryEditCommand < Command
      include EntryCommandUtils

      command("edit",
              ["entry:edit",
               "entry:update",
               "update",
               "e"],
              _("Edit the entry."),
              _("usage: edit <ID> [OPTIONS]"))
      
      def initialize(*args)
        super
        @options.push(IntOption.new("i", "id", "ID", _("Entry ID.")))
      end

      # 機密情報を追加する。
      def save
        # TODO: undo スタックに操作を追加する。
        apply_entry_changes
      end

      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["id"] = argv.shift.to_i
        end
        if config["id"].nil?
          puts(_("Too few arguments."))
          help
          return true
        end
        @entry = world.entry_collection.find(config["id"])
        if @entry.nil?
          raise NoSuchEntry.new("id" => config["id"])
        end
        puts(_("Edit the entry."))
        @attributes = @entry.duplicate_attributes
        @tags = @entry.tags.dup
        if @tags.empty?
          @tags = input_tags(@tags) || []
        end
        command_loop
        return true
      end
    end

    # 機密情報を検索するコマンドを表現する。
    class EntryShowCommand < Command
      include EntryCommandUtils
      
      command("show",
              ["entry:show",
               "s"],
              _("Show the entry."),
              _("usage: show <ID> [OPTIONS]"))
      
      def initialize(*args)
        super
        @config["show_secret"] = false
        @options.push(IntOption.new("id", _("Entry ID.")),
                      BoolOption.new("s", "show_secret",
                                     _("Show value of secret attributes.")))
      end

      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["id"] = argv.shift.to_i
        end
        if config["id"].nil?
          puts(_("Too few arguments."))
          help
          return true
        end
        entries = world.entry_collection.entries
        entry = entries.find { |entry|
          entry.id == config["id"]
        }
        if !entry
          raise NoSuchEntry.new("id" => config["id"])
        end
        display_entry(entry)
        if config["show_secret"]
          # TODO: undo スタックに操作を追加する。
          entry.rate += 1
          world.changed = true
          puts(_("Changed rate to %d.") % entry.rate)
        end
        return true
      end
    end

    # 機密情報を検索するコマンドを表現する。
    class EntrySearchCommand < Command
      include EntryCommandUtils
      
      command("search",
              ["entry:search",
               "entry:list",
               "list",
               "ls",
               "l"],
              _("Search the entry."),
              _("usage: search [QUERY] [OPTIONS]"))
      
      def initialize(*args)
        super
        @config["query"] = ""
        @config["tags"] = []
        @config["num"] = 10
        @config["ignore-case"] = false
        @options.push(StringOption.new("query", _("Query.")), 
                      ArrayOption.new("tags", _("Tags.")),
                      IntOption.new("n", "num", _("Number of entries.")),
                      BoolOption.new("i", "ignore_case", _("Ignore case.")))
      end

      def search(entries, words, tags, ignore_case)
        if words.empty?
          matched_entries = entries
        else
          matched_entries = entries.select { |entry|
            s = entry.attributes.collect { |attr|
              attr.value.to_s
            }.join("\n")
            res = true
            if ignore_case
              s.downcase!
              words.each(&:downcase!)
            end
            words.each do |word|
              if !s.include?(word)
                res = false
                break
              end
            end
            res
          }
        end
        if tags.length > 0
          matched_entries = matched_entries.select { |entry|
            tags == (entry.tags & tags)
          }
        end
        return matched_entries
      end
      
      # コマンドを実行する。
      def run(argv)
        option_parser.parse!(argv)
        if argv.length > 0
          config["query"].concat(" " + argv.join(" "))
        end
        words = config["query"].split
        entries = search(world.entry_collection.entries,
                         words, config["tags"], config["ignore_case"])
        if entries.empty?
          puts(_("No entry."))
        else
          sort_key = :id
          page_no = 1
          per_page = ENV["LINES"].to_i
          if per_page <= 3
            per_page = 25 - 3
          else
            per_page -= 3
          end
          current_mode = :next

          begin
            loop do
              begin
                if words.length > 0
                  print(_("Search result of '%s', %d entries.") %
                        [words.join(" "), entries.length])
                else
                  print(_("List of %d entries.") % entries.length)
                end
                num_pages = (entries.length.to_f / per_page).ceil
                puts(_(" [page %d/%d]") % [page_no, num_pages])
                
                list_entries(entries, sort_key, page_no, per_page)

                if num_pages == 1
                  raise Interrupt
                end

                prompt = _("Command (p:prev, n:next, s:sort, q:quit): ")
                input = S7nCli.input_string(prompt)
                if input.nil?
                  raise Interrupt
                end
                begin
                  case input
                  when /\A(n|next)\z/i
                    page_no += 1
                    current_mode = :next
                  when /\A(p|prev)\z/i
                    page_no -= 1
                    current_mode = :prev
                  when /\A(s|sort)\z/i
                    sort_key = next_sort_key(sort_key)
                  when /\A(q|quit)/i
                    break
                  else
                    if current_mode == :next
                      page_no += 1
                    else
                      page_no -= 1
                    end
                  end
                  if page_no < 1
                    page_no = 1
                  elsif page_no >= num_pages
                    page_no = num_pages
                  end
                end
              rescue ApplicationError => e
                puts(e.message)
              end
            end
          rescue Interrupt
            puts("\n")
          end
        end
        return true
      end

      # ソート対象の属性の配列。
      SORT_KEYS = [:id, :name, :tags, :rate]
      
      def next_sort_key(current)
        return SORT_KEYS[(SORT_KEYS.index(current) + 1) % SORT_KEYS.length]
      end

      # 指定した文字列 str の表示幅が width よりも長い場合は切り詰める。
      # width よりも短い場合、left が true だと右部分にスペースをつめ、
      # left が false だと、左部分にスペースをつめる。
      def truncate_or_add_space(str, width, left = true)
        len = 0
        truncate_index = nil
        truncate_with_space = false
        str.chars.each_with_index do |chr, i|
          case UnicodeData.east_asian_width(chr)
          when :H, :N
            n = 1
          else
            n = 2
          end
          len += n
          if truncate_index.nil? && len >= width
            truncate_index = i
            if len > width
              truncate_with_space = true
            end
          end
        end
        if len < width
          space = " " * (width - len)
          if left
            res = str + space
          else
            res = space + str
          end
        elsif len == width
          res = str
        else
          res = str[0..truncate_index]
          if truncate_with_space
            res[-1] = " "
          end
        end
        return res
      end

      def list_entries(entries, sort_key, page_no, per_page)
        sort_marks = [" ", " ", " ", " "]
        sort_marks[SORT_KEYS.index(sort_key)] = ">"
        puts(_("%sID |%sName                                           |%sTags(s)            |%sRate") % sort_marks)
        sorted_entries = entries.sort_by { |e| e.send(sort_key) }
        sorted_entries[((page_no - 1) * per_page), per_page].each do |entry|
          puts([truncate_or_add_space(entry.id.to_s, 4, false),
                truncate_or_add_space(entry.name, 48),
                truncate_or_add_space(entry.tags.join(","), 20),
                truncate_or_add_space(entry.rate.to_s, 5, false)].join("|"))
        end
      end
    end

    # 機密情報を削除するコマンドを表現する。
    class EntryDeleteCommand < Command
      include EntryCommandUtils

      command("delete",
              ["entry:delete",
               "entry:destroy",
               "entry:remove",
               "destroy",
               "remove",
               "del",
               "rm",
               "d"],
              _("Delete the entry."),
              _("usage: delete <ID>"))
      
      # コマンドを実行する。
      def run(argv)
        if argv.length > 0
          id = argv.shift.to_i
        end
        if id.nil?
          puts(_("Too few arguments."))
          help
          return true
        end
        entry = world.entry_collection.find(id)
        if entry.nil?
          raise NoSuchEntry.new("id" => id)
        end
        display_entry(entry)
        puts("-----")
        if S7nCli.input_boolean(_("Delete? (no): "))
          # TODO: undo スタックに操作を追加。
          world.entry_collection.delete_entries(entry)
          world.changed = true
          puts(_("Deleted: %d") % entry.id)
        else
          canceled
        end
        return true
      end
    end
  end
end
