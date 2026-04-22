# frozen_string_literal: true

# == Schema Information
#
# Table name: rails_url_shortener_ipgeos
#
#  id                   :integer          not null, primary key
#  ip                   :string
#  country_name         :string
#  country_code         :string
#  region_code          :string
#  region_name          :string
#  city_name            :string
#  latitude             :string
#  longitude            :string
#  timezone             :string
#  isp                  :string
#  org                  :string
#  as                   :string
#  mobile               :boolean
#  proxy                :boolean
#  hosting              :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  continent_name       :string
#  continent_code       :string
#  district             :string
#  zip_code             :string
#  offset               :string
#  currency_name        :string
#  currency_code        :string
#  asname               :string
#  asn                  :string
#  host_name            :string
#  backend              :string
#  network              :string
#  ip_version           :string
#  provider             :string
#  country_capital_name :string
#  country_tld          :string
#  in_eu                :boolean
#  country_calling_code :string
#  languages            :string
#  country_area         :float
#  country_code_iso3    :string
#  utc_offset           :string
#
module RailsUrlShortener
  class Ipgeo < ApplicationRecord
    has_many :visits, dependent: :nullify
    has_many :urls, through: :visits

    def update_from_remote
      return unless RailsUrlShortener.ip_lookup_backend.respond_to?(:call)

      result = RailsUrlShortener.ip_lookup_backend.call(ip, RailsUrlShortener.ip_lookup_api_key)

      return unless result.is_a?(Hash)

      update(result.stringify_keys.slice(*Ipgeo.column_names))
    end
  end
end
