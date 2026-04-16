class AddPausedToRailsUrlShortenerUrls < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:rails_url_shortener_urls, :paused)
      add_column :rails_url_shortener_urls, :paused, :boolean, default: false, null: false
    end
  end
end
