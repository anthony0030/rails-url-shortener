class AddKindToRailsUrlShortenerUrls < ActiveRecord::Migration[7.2]
  def change
    add_column :rails_url_shortener_urls, :kind, :string

    add_index :rails_url_shortener_urls, [:owner_type, :owner_id, :kind], name: "index_urls_on_owner_and_kind"
  end
end
