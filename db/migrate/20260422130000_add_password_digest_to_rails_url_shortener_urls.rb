# frozen_string_literal: true

class AddPasswordDigestToRailsUrlShortenerUrls < ActiveRecord::Migration[7.0]
  def change
    add_column :rails_url_shortener_urls, :password_digest, :string
  end
end
