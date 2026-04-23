# frozen_string_literal: true

class AddRedirectStatusToRailsUrlShortenerUrls < ActiveRecord::Migration[6.0]
  def change
    add_column :rails_url_shortener_urls, :redirect_status, :integer
  end
end
