require 'ostruct'
require 'test_helper'

module RailsUrlShortener
  class HostConstraintTest < ActiveSupport::TestCase
    def mock_request(host)
      if host.include?(':')
        host_only = host.split(':').first
        OpenStruct.new(host: host_only, host_with_port: host)
      else
        OpenStruct.new(host: host, host_with_port: host)
      end
    end

    test 'matches? returns true when enforce_host_constraint is false' do
      RailsUrlShortener.enforce_host_constraint = false
      assert HostConstraint.matches?(mock_request('anything.com'))
    ensure
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'matches? returns true for global host' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com'
      assert HostConstraint.matches?(mock_request('short.example.com'))
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'matches? returns true for global host with port' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com:3000'
      assert HostConstraint.matches?(mock_request('short.example.com:3000'))
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'matches? returns true for custom_hosts value' do
      RailsUrlShortener.enforce_host_constraint = true
      RailsUrlShortener.custom_hosts = { 'marketing' => 'mkt.example.com' }
      assert HostConstraint.matches?(mock_request('mkt.example.com'))
    ensure
      RailsUrlShortener.custom_hosts = {}
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'matches? returns false for unknown host' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com'
      RailsUrlShortener.custom_hosts = { 'marketing' => 'mkt.example.com' }
      assert_not HostConstraint.matches?(mock_request('evil.com'))
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.custom_hosts = {}
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'matches? allows host without port when config has port' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com:3000'
      assert HostConstraint.matches?(mock_request('short.example.com'))
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'allowed_hosts includes global host and custom_hosts values' do
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com'
      RailsUrlShortener.custom_hosts = { 'marketing' => 'mkt.example.com', 'support' => 'help.example.com' }
      allowed = HostConstraint.allowed_hosts
      assert_includes allowed, 'short.example.com'
      assert_includes allowed, 'mkt.example.com'
      assert_includes allowed, 'help.example.com'
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.custom_hosts = {}
    end

    test 'allowed_hosts strips port for comparison' do
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com:3000'
      allowed = HostConstraint.allowed_hosts
      assert_includes allowed, 'short.example.com:3000'
      assert_includes allowed, 'short.example.com'
    ensure
      RailsUrlShortener.host = original_host
    end
  end
end
