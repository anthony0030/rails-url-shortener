class User < ApplicationRecord
  include RailsUrlShortener::Shortenable

  has_short_url :url
end
