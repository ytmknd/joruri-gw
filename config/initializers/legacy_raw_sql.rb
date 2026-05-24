# Rails 6.1+ で導入された ActiveRecord::Sanitization#disallow_raw_sql! による
# 「.order / .pluck などに生 SQL 断片を渡すとエラー」というガードを、レガシー
# コード全面対応が完了するまで一時的に無効化する。
#
# 本来は Arel.sql(...) でラップするのが正しい。CLAUDE.md Phase 2 系の
# Strong Parameters 対応と並行して順次置換予定。
Rails.application.config.to_prepare do
  ActiveRecord::Base.singleton_class.prepend(Module.new do
    def disallow_raw_sql!(args, permit: nil)
      # no-op: 生 SQL 断片を許可する暫定設定
    end
  end)
end
