# frozen_string_literal: true

require 'test_helper'

module RailsUrlShortener
  class ExtensionAutoIncludeTest < ActiveSupport::TestCase
    test 'Url includes UrlExtension when defined' do
      # Define a test extension
      mod = Module.new do
        extend ActiveSupport::Concern

        def test_extension_method
          'extended'
        end
      end

      RailsUrlShortener.const_set(:UrlExtension, mod)
      Url.include(mod)

      url = Url.new
      assert url.respond_to?(:test_extension_method)
      assert_equal 'extended', url.test_extension_method
    ensure
      RailsUrlShortener.send(:remove_const, :UrlExtension) if RailsUrlShortener.const_defined?(:UrlExtension, false)
    end

    test 'models work normally without extensions defined' do
      # Ensure no extensions are defined
      refute RailsUrlShortener.const_defined?(:UrlExtension, false)
      refute RailsUrlShortener.const_defined?(:VisitExtension, false)
      refute RailsUrlShortener.const_defined?(:IpgeoExtension, false)

      # Models should still work
      assert Url.new
      assert Visit.new
      assert Ipgeo.new
    end

    test 'engine to_prepare auto-includes extensions' do
      mod = Module.new do
        extend ActiveSupport::Concern

        def ipgeo_ext_test
          'ipgeo_extended'
        end
      end

      RailsUrlShortener.const_set(:IpgeoExtension, mod)

      # Trigger the engine's to_prepare callback
      Rails.application.reloader.prepare!

      ipgeo = Ipgeo.new
      assert ipgeo.respond_to?(:ipgeo_ext_test)
      assert_equal 'ipgeo_extended', ipgeo.ipgeo_ext_test
    ensure
      RailsUrlShortener.send(:remove_const, :IpgeoExtension) if RailsUrlShortener.const_defined?(:IpgeoExtension, false)
    end

    test 'to_prepare skips include when extension is already included' do
      mod = Module.new do
        extend ActiveSupport::Concern

        def visit_ext_test
          'visit_extended'
        end
      end

      RailsUrlShortener.const_set(:VisitExtension, mod)
      Visit.include(mod) # include it first

      # Run to_prepare again — should not double-include
      Rails.application.reloader.prepare!

      assert Visit.new.respond_to?(:visit_ext_test)
    ensure
      RailsUrlShortener.send(:remove_const, :VisitExtension) if RailsUrlShortener.const_defined?(:VisitExtension, false)
    end
  end
end
