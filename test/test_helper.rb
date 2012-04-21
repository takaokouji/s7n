# -*- coding: utf-8 -*-
$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

require "test/unit"
require "pp"
require "tempfile"
require "stringio"
require "gettext"
require "shoulda"

class Test::Unit::TestCase
  include GetText
end

module Shoulda
  module Context
    class Context # :nodoc:
      def full_name
        parent_name = parent.full_name if am_subcontext?
        return [parent_name, name].compact.join("の").strip
      end

      def create_test_from_should_hash(should)
        test_name = ["test:", full_name, "は", "#{should[:name]}"].flatten.join('').to_sym

        if test_methods[test_unit_class][test_name.to_s] then
          warn "  * WARNING: '#{test_name}' is already defined"
        end

        test_methods[test_unit_class][test_name.to_s] = true

        context = self
        test_unit_class.send(:define_method, test_name) do
          @shoulda_context = context
          begin
            context.run_parent_setup_blocks(self)
            should[:before].bind(self).call if should[:before]
            context.run_current_setup_blocks(self)
            should[:block].bind(self).call
          ensure
            context.run_all_teardown_blocks(self)
          end
        end
      end
    end
  end
end
