# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Rails 6.1 + Ruby 2.7: ensure Logger is available before ActiveSupport loads
require 'logger'

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
