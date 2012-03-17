$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

require "test/unit"
require "pp"
require "tempfile"
require "stringio"
require "gettext"

class Test::Unit::TestCase
  include GetText
end
