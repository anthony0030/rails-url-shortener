# frozen_string_literal: true

module RailsUrlShortener
  module UrlsHelper
    ##
    # helper for generate short urls
    #
    # this method return a short url or the original url if something is bad
    # Usage:
    # short_url("https://tools.ietf.org/search/rfc2616#section-5.3")
    def short_url(url, owner: nil, key: nil, kind: nil, starts_at: nil, expires_at: nil, paused: false, category: nil, forward_query_params: nil, url_options: {})
      # generate
      url_object = Url.generate(
        url,
        owner: owner,
        key: key,
        kind: kind,
        starts_at: starts_at,
        expires_at: expires_at,
        paused: paused,
        category: category,
        forward_query_params: forward_query_params
      )

      if url_object.errors.empty?
        # options for url_for
        options = {
          controller: 'rails_url_shortener/urls',
          action: 'show',
          key: url_object.key,
          host: RailsUrlShortener.host
        }.merge(url_options)

        # use helper of this engine
        RailsUrlShortener::Engine.routes.url_for(options)
      else
        # if not saved, return original url
        url
      end
    end
  end
end
