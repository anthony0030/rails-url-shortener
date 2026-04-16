class RemoveOwnerIndexFromRailsUrlShortenerUrls < ActiveRecord::Migration[7.2]
  def change
    remove_index :rails_url_shortener_urls, name: :index_rails_url_shortener_urls_on_owner
  end
end
