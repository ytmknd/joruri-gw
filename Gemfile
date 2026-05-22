source 'https://rubygems.org'

gem 'rails', '~> 5.0.7'

gem 'activerecord-session_store', '~> 1.1'
# activerecord-deprecated_finders removed — dynamic finders rewritten (Phase 2)
# protected_attributes removed — use strong parameters (Phase 2)

gem 'mysql2', '>= 0.3.13', '< 0.5'

# Ruby 2.3 supports nokogiri <= 1.10.x; loofah 2.21+ requires Nokogiri::HTML4 (added in
# nokogiri 1.14) so pin to the last compatible versions for Ruby 2.3
# nokogiri 1.10.x は Ruby 2.3 最後の対応シリーズ
gem 'nokogiri', '1.10.10'
gem 'loofah', '~> 2.19.1'
gem 'rails-html-sanitizer', '~> 1.4.4'

gem 'ruby-ldap', '0.9.16'
gem 'will_paginate', '~> 3.1'
# jpmobile removed — mobile support dropped (Phase 2)
# tamtam removed — depended on jpmobile
gem 'net-ssh', '2.9.1'
gem 'rmagick', '2.15.4', require: false
gem 'hpricot', '0.8.4'
# zipruby incompatible with libzip 1.x; replaced with rubyzip
gem 'rubyzip', '~> 1.3', require: 'zip'
# icalendar 2.x requires Ruby >= 2.4; stay on 1.x for Ruby 2.3 (Phase 2 Rails 5)
# Upgrade to 2.x when Ruby >= 2.4 (Phase 3)
gem 'icalendar', '1.5.4'
gem 'ri_cal', '0.8.8'
# gem 'ri_cal', '0.8.8'
gem 'render_component_vho', '3.2.1'
gem 'dalli', '~> 2.7'
# dynamic_form removed — incompatible with Rails 5 (Phase 2)
gem 'acts_as_tree', '~> 2.1.0'
gem 'calendar_date_select', '2.0.0'
gem 'validates_email_format_of', '1.5.3'
gem 'wsse', '~> 0.0.2'
gem 'delayed_job_active_record', '~> 4.1'
gem 'daemons', '~> 1.1.9'
gem 'whenever', '~> 0.9.2'
gem 'atomutil', '~> 0.1.4'
gem 'hikidoc', '~> 0.1.0'
gem 'memoist', '~> 0.11.0'
gem 'prawn', '2.0.1'
gem 'prawn-table', '0.2.1'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1'

gem 'jquery-rails', '~> 4.0'
gem 'jquery-ui-rails', '~> 5.0.0'
gem 'jquery-timepicker-addon-rails', '~> 1.4.1'

gem 'jquery-fileupload-rails'

gem 'jbuilder', '~> 2.0'

group :doc do
  gem 'sdoc', require: false
end

group :development do
  gem 'rack-mini-profiler'
  gem 'rb-readline', '~> 0.5.1'
  gem 'listen', '~> 3.0.5'
  gem 'brakeman', require: false
end

gem 'capistrano', '~> 3.4.0'
