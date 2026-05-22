# Rails 5.0 new framework defaults
# Enable after verifying each option does not break the app

# Rails 5 では belongs_to が required になるが、optional: true を各モデルに追加済み
# 万が一の既存コード互換のため false に設定し、Phase 3 で削除予定
Rails.application.config.active_record.belongs_to_required_by_default = false

# Rails 5 から :sorted が :random に変更される警告を抑制
Rails.application.config.active_support.test_order = :random
