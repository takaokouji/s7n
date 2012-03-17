# -*- coding: utf-8 -*-

# gettext のモック
module GetText
  def self.included(mod)
    class << mod
      def _(s)
        return s
      end

      def N_(s)
        return s
      end
    end
  end

  def _(s)
    return s
  end

  def N_(s)
    return s
  end

  def bindtextdomain(*args)
  end
  module_function :bindtextdomain
end
