# frozen_string_literal: true

require 'rails_url_shortener/version'
require 'rails_url_shortener/engine'
require 'rails_url_shortener/model'
require 'rails_url_shortener/ip_lookup'
require 'rails_url_shortener/host_constraint'
require 'rails_url_shortener/root_handler'
require_relative '../app/helpers/rails_url_shortener/urls_helper'

module RailsUrlShortener
  ##
  # constants
  CHARSETS = {
    alphanum: ('a'..'z').to_a + (0..9).to_a,
    alphacase: ('a'..'z').to_a + ('A'..'Z').to_a,
    alphanumcase: ('A'..'Z').to_a + ('a'..'z').to_a + (0..9).to_a
  }.freeze

  ##
  # host for build final url on helper
  mattr_accessor :host, default: 'test.host'

  ##
  # default redirection url when the key isn't found
  mattr_accessor :default_redirect, default: '/'

  ##
  # charset for generate keys
  mattr_accessor :charset, default: CHARSETS[:alphanumcase]

  ##
  # default key length used by random keys
  mattr_accessor :key_length, default: 6

  ##
  # minimum key length for custom keys
  mattr_accessor :minimum_key_length, default: 3

  ##
  # if save bots visits on db, the detection is provided by browser gem
  # and is described like "The bot detection is quite aggressive"
  # so if you put this configuration like false could lose some visits to your link
  # by default saving all requests
  mattr_accessor :save_bots_visits, default: true

  mattr_accessor :save_visits, default: true

  ##
  # if true, the key column on Url cannot be updated after creation
  mattr_accessor :disable_url_key_updates, default: false

  ##
  # if true, query parameters from the short URL request are forwarded to the redirect destination
  mattr_accessor :forward_query_params, default: false

  ##
  # IP geolocation lookup backend.
  # Must respond to #call(ip_address, api_key) and
  # Must return a Hash of attributes on success (with underscore keys matching Ipgeo column names)
  # Must return nil on failure.
  # Built-in options:
  #  nil (IP geolocation lookups are skipped)
  #  RailsUrlShortener::IpLookup::IP_API_COM
  #  RailsUrlShortener::IpLookup::IPAPI_CO
  mattr_accessor :ip_lookup_backend, default: nil

  ##
  # API key passed to the IP lookup backend (optional, depends on provider)
  mattr_accessor :ip_lookup_api_key, default: nil

  ##
  # Mapping of logical custom_host keys to actual hostnames per environment.
  # Example: { 'marketing' => 'mkt.example.com', 'support' => 'help.example.com' }
  # Used by to_short_url and short_url to resolve the custom_host column value.
  mattr_accessor :custom_hosts, default: {}

  ##
  # When true, the engine's route only matches requests whose host is in the
  # allowed hosts list (RailsUrlShortener.host + custom_hosts values).
  # Useful when the engine is mounted at root to prevent it from catching
  # requests meant for other hosts.
  mattr_accessor :enforce_host_constraint, default: false

  ##
  # When true, GET / on the engine redirects to default_redirect
  # or returns 404 if default_redirect is blank
  # instead of falling through to the host app.
  mattr_accessor :block_root, default: false

  ##
  # Resolve a custom_host key to an actual hostname.
  # Returns the mapped hostname if found, otherwise falls back to the global host.
  def self.resolve_host(custom_host_key)
    return host if custom_host_key.blank?

    custom_hosts[custom_host_key.to_s] || custom_hosts[custom_host_key.to_sym] || host
  end
end

ActiveSupport.on_load(:active_record) do
  extend RailsUrlShortener::Model
end

ActiveSupport.on_load(:action_view) do
  prepend RailsUrlShortener::UrlsHelper
end

ActiveSupport.on_load(:action_controller_base) do
  prepend RailsUrlShortener::UrlsHelper
end
