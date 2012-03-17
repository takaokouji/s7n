# -*- coding: utf-8 -*-

module S7n
  # UNICODE に関する処理を表現する。
  module UnicodeData
    module_function

    # chr で指定された 1 文字の文字幅を示す次のシンボルを返す。
    # :F:: East Asian Full-width
    # :H:: East Asian Half-width
    # :W:: East Asian Wide
    # :Na:: East Asian Narrow (Na)
    # :A:: East Asian Ambiguous (A)
    # :N:: Not East Asian
    # 2 文字以上が与えられた場合、最初の 1 文字を対象とする。
    #
    # まだ、ASCII と半角カナにしか対応していない。
    def east_asian_width(chr)
      n = chr[0].encode("UTF-8").ord
      if n >= 0 && n <= 127 || n == 0x203E
        return :N
      elsif n >= 0xFF61 && n <= 0xFF9F
        return :H
      else
        return :F
      end
    end
  end
end
