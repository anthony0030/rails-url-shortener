module RailsUrlShortener
  module Model
    # rubocop:disable Naming/PredicatePrefix

    # Legacy method for backward compatibility.
    # For more customizable options, use `include RailsUrlShortener::Shortenable` directly.
    def has_short_urls
      class_eval do
        has_many :urls, class_name: 'RailsUrlShortener::Url', as: 'owner'
      end
    end

    # rubocop:enable Naming/PredicatePrefix
  end
end
