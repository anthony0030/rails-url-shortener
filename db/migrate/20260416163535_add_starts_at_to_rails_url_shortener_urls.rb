class AddStartsAtToRailsUrlShortenerUrls < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:rails_url_shortener_urls, :starts_at)
      add_column :rails_url_shortener_urls, :starts_at, :datetime
    end
  end
end
