# frozen_string_literal: true

class AddTrackedToRailsUrlShortenerUrls < ActiveRecord::Migration[7.0]
  def change
    add_column :rails_url_shortener_urls, :tracked, :boolean, default: true, null: false
  end
end
