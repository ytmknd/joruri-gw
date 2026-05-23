# Rails session store configuration
# Use ActiveRecord to store sessions in ar_sessions table
Rails.application.config.session_store :active_record_store, key: '_jorurigw_session'

# Phase 5: activerecord-session_store 2.x + Rails 8 compatibility
# The Session model uses the primary database connection (no separate :session DB)
