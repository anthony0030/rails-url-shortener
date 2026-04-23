# frozen_string_literal: true

class AddCustomHostToRailsUrlShortenerUrls < ActiveRecord::Migration[7.0]
  def change
    add_column :rails_url_shortener_urls, :custom_host, :string
  end
end
