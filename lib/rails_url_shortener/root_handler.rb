# frozen_string_literal: true

module RailsUrlShortener
  # Rack application that handles GET / on the engine mount point.
  # When block_root is true, redirects to default_redirect or returns 404.
  # When block_root is false, the route constraint skips this handler entirely.
  class RootHandler
    def self.call(env)
      target = RailsUrlShortener.default_redirect
      if target.present?
        [302, { 'Location' => target, 'Content-Type' => 'text/html' }, []]
      else
        [404, {}, []]
      end
    end
  end
end
