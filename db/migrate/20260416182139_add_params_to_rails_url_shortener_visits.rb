class AddParamsToRailsUrlShortenerVisits < ActiveRecord::Migration[7.2]
  def change
    add_column :rails_url_shortener_visits, :params, :text
  end
end
