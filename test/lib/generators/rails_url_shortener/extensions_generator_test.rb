# frozen_string_literal: true

require 'test_helper'
require 'generators/rails_url_shortener/extensions_generator'

class RailsUrlShortener::ExtensionsGeneratorTest < Rails::Generators::TestCase
  tests RailsUrlShortener::ExtensionsGenerator
  destination Rails.root.join('tmp/generators')

  setup :prepare_destination

  test 'generates all extension files' do
    run_generator

    assert_file 'app/models/concerns/rails_url_shortener/url_extension.rb' do |content|
      assert_match(/module RailsUrlShortener::UrlExtension/, content)
      assert_match(/extend ActiveSupport::Concern/, content)
    end

    assert_file 'app/models/concerns/rails_url_shortener/visit_extension.rb' do |content|
      assert_match(/module RailsUrlShortener::VisitExtension/, content)
    end

    assert_file 'app/models/concerns/rails_url_shortener/ipgeo_extension.rb' do |content|
      assert_match(/module RailsUrlShortener::IpgeoExtension/, content)
    end
  end
end
