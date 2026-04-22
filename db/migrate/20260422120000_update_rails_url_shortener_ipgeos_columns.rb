# frozen_string_literal: true

class UpdateRailsUrlShortenerIpgeosColumns < ActiveRecord::Migration[7.0]
  def change
    change_table :rails_url_shortener_ipgeos do |t|
      # Renames
      t.rename :country, :country_name
      t.rename :region, :region_code
      t.rename :city, :city_name
      t.rename :lat, :latitude
      t.rename :lon, :longitude

      # New columns
      t.string  :continent_name
      t.string  :continent_code
      t.string  :district
      t.string  :zip_code
      t.string  :offset
      t.string  :currency_name
      t.string  :currency_code
      t.string  :asname
      t.string  :asn
      t.string  :host_name
      t.string  :backend
      t.string  :network
      t.string  :ip_version
      t.string  :provider
      t.string  :country_capital_name
      t.string  :country_tld
      t.boolean :in_eu
      t.string  :country_calling_code
      t.string  :languages
      t.float   :country_area
      t.string  :country_code_iso3
      t.string  :utc_offset
    end
  end
end
