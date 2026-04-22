class AddForwardQueryParamsToRailsUrlShortenerUrls < ActiveRecord::Migration[7.0]
  def change
    add_column :rails_url_shortener_urls, :forward_query_params, :boolean, default: nil
  end
end
