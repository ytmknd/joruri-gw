require File.expand_path('../boot', __FILE__)

require 'rails/all'

# alias_method_chain was removed in Rails 5.2.
# render_component_vho 3.2.1 calls it during gem load — restore it before Bundler.require.
unless Module.method_defined?(:alias_method_chain)
  Module.define_method(:alias_method_chain) do |target, feature|
    alias_method :"#{target}_without_#{feature}", target
    alias_method target, :"#{target}_with_#{feature}"
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JoruriGw
  class Application < Rails::Application
    require "#{Rails.root}/lib/joruri"
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Rails 6.1: activerecord-session_store が legacy connection handling を必要とする
    # Rails 7.2 で削除されるため Phase 4 で対処する
    config.active_record.legacy_connection_handling = true if Rails::VERSION::MAJOR == 6

    # Rails 7 + Zeitwerk: lib/ の naming が Zeitwerk 非準拠のため autoload から除外
    # (CLAUDE.md Phase 3-1 参照) — lib/ のファイルは明示的 require で管理
    config.autoload_paths += %W(#{config.root}/lib)
    # lib/ を Zeitwerk の監視から除外（autoload_paths は互換のため残す）
    config.watchable_dirs["#{config.root}/lib"] = [:rb]
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.default_locale = :ja
    Dir::entries("#{Rails.root}/config/modules").each do |mod|
      next if mod =~ /^\./
      Dir::glob("#{Rails.root}/config/modules/#{mod}/locales/*.yml").each do |file|
        config.i18n.load_path << file if FileTest.exist?(file)
      end
    end
    config.x = ActiveSupport::OrderedOptions.new
    Dir::entries("#{Rails.root}/config/modules").each do |mod|
      next if mod =~ /^\./
      config.x[mod] = ActiveSupport::OrderedOptions.new
      Dir::glob("#{Rails.root}/config/modules/#{mod}/settings/*.yml").each do |file|
        next unless FileTest.exist?(file)
        # Ruby 3.1+ Psych 4.x: aliases: true が必要（YAML anchor/merge key 対応）
        yaml_opts = YAML.respond_to?(:unsafe_load_file) ? {aliases: true} : {}
        YAML.load_file(file, **yaml_opts)[Rails.env].each do |k, v|
          config.x[mod][k] = v.is_a?(Hash) ? v.with_indifferent_access : v
        end
      end
    end
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # whitelist_attributes removed in Rails 5 (was part of protected_attributes gem)
    # Strong Parameters 未対応のレガシーコントローラ (270+) を一括で動かすため、
    # ActionController::Parameters を Hash 互換として扱う暫定設定。
    # 本格的な Strong Parameters 移行は Phase 2 タスクとして順次実施予定。
    config.action_controller.permit_all_parameters = true
  end
end

AppConfig = Rails.application.config.x
