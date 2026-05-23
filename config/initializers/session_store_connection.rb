# activerecord-session_store 2.x + Rails 6.1: Session モデルに明示的に接続プールを設定
# Rails 6.1 のマルチDB対応により Session モデルが接続を見つけられない問題を修正
ActiveSupport.on_load(:active_record) do
  if defined?(ActiveRecord::SessionStore::Session)
    db_config = Rails.application.config.database_configuration[Rails.env.to_s]
    ActiveRecord::SessionStore::Session.establish_connection(db_config) if db_config
  end
end
