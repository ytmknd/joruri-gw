source 'https://rubygems.org'

gem 'rails', '~> 8.0.0'

gem 'activerecord-session_store', '~> 2.1'
gem 'puma', '~> 6.0'

gem 'mysql2', '~> 0.5'

gem 'nokogiri', '~> 1.19'
gem 'loofah', '~> 2.21'
gem 'rails-html-sanitizer', '~> 1.6'

# ruby-ldap removed in Phase 5 (Ruby 4.0 incompatible — rb_tainted_str_new removed)
# Replace with net-ldap in a future phase if LDAP is needed
gem 'will_paginate', '~> 4.0'
gem 'net-ssh', '~> 7.2'
gem 'rmagick', '~> 6.0', require: false
# hpricot removed in Phase 5 (Ruby 4.0 incompatible) — replaced with nokogiri
gem 'rubyzip', '~> 2.3', require: 'zip'
gem 'icalendar', '~> 2.10'
gem 'render_component_vho', '3.2.1'
gem 'dalli', '~> 3.2'
gem 'acts_as_tree', '~> 2.9'
gem 'calendar_date_select', '2.0.0'
gem 'validates_email_format_of', '~> 1.6'
gem 'wsse', '~> 0.0.2'
gem 'delayed_job_active_record', '~> 4.1'
gem 'daemons', '~> 1.4'
gem 'whenever', '~> 1.0'
gem 'atomutil', '~> 0.1.4'
gem 'hikidoc', '~> 0.1.0'
gem 'memoist', '~> 0.16'
gem 'prawn', '~> 2.5'
gem 'prawn-table', '~> 0.2'

# Use Dart Sass (sass-rails uses sassc which supports Ruby 4)
gem 'sass-rails', '~> 6.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.0'

# CoffeeScript (still in use)
gem 'coffee-rails', '~> 5.0'

gem 'jquery-rails', '~> 4.6'
gem 'jquery-ui-rails', '~> 7.0'
gem 'jquery-timepicker-addon-rails'

gem 'jquery-fileupload-rails'

gem 'jbuilder', '~> 2.11'

group :development do
  gem 'listen', '~> 3.8'
  gem 'brakeman', require: false
end

gem 'capistrano', '~> 3.18'
gem 'capistrano-rails', require: false

# Ruby 3.x+ で stdlib から分離されたgem
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'matrix', require: false
gem 'rexml'
gem 'nkf'    # Ruby 4.0 で stdlib から分離（kconv も含む）
gem 'csv'    # Ruby 3.4 で stdlib から分離
