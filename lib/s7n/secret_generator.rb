# -*- coding: utf-8 -*-

module S7n
  # パスワードや暗証番号などの機密情報を自動生成する処理を表現する。
  class SecretGenerator
    # 文字の集合を示すシンボルから実際の文字の配列へのハッシュ。
    SYMBOL_CHARACTERS = {
      :alphabet => ("a".."z").to_a + ("A".."Z").to_a,
      :upper_alphabet => ("A".."Z").to_a,
      :lower_alphabet => ("a".."z").to_a,
      :number => ("0".."9").to_a,
      # TODO: アスキーコードの表を確認する。
      :symbol => '!"#$%&\'()-=^~\\|@`[{;+:*]},<.>/?_'.scan(%r"."),
    }
    
    def self.generate(options)
      res = ""
      characters = []
      (options[:characters] || [:alphabet, :number]).each do |sym|
        if SYMBOL_CHARACTERS.key?(sym)
          characters.concat(SYMBOL_CHARACTERS[sym])
        end
      end
      options[:length].times do
        res << characters[rand(characters.length)]
      end
      return res
    end
  end
end
