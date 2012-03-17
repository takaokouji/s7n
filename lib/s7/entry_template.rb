module S7
  # 機密情報の新規作成時に利用するテンプレートを表現する。
  class EntryTemplate
    # 名前。
    attr_accessor :name

    # 属性の配列。
    attr_accessor :attributes
  end
end
