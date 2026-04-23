# frozen_string_literal: true

module RailsUrlShortener
  ##
  # A routing constraint that only matches requests whose host is one of the
  # configured short-link hosts (RailsUrlShortener.host + custom_hosts values).
  #
  # Activated by setting:
  #   RailsUrlShortener.enforce_host_constraint = true
  #
  # When enforce_host_constraint is false (default), this constraint allows all requests.
  #
  # Can also be applied manually in host app routes:
  #   mount RailsUrlShortener::Engine => '/', constraints: RailsUrlShortener::HostConstraint
  #
  class HostConstraint
    def self.matches?(request)
      return true unless RailsUrlShortener.enforce_host_constraint

      allowed = allowed_hosts
      allowed.include?(request.host) || allowed.include?(request.host_with_port)
    end

    def self.allowed_hosts
      hosts = RailsUrlShortener.custom_hosts.values << RailsUrlShortener.host
      hosts.flat_map { |h| [h, h.split(':').first] }.uniq
    end
  end
end
