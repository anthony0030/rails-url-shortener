# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in rails_url_shortener.gemspec.
gemspec

gem 'rails', '~> 8.1.0'

gem 'sqlite3'

gem 'sprockets-rails'

group :development, :test do
  gem 'byebug'
  gem 'ostruct'
  gem 'db-annotate'
  gem 'faker'
  gem 'minitest'
  gem 'rubocop'
  gem 'rubocop-rails', require: false
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end
