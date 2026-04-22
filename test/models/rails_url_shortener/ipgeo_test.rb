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
require 'test_helper'

module RailsUrlShortener
  class IpgeoTest < ActiveSupport::TestCase
    test 'create only with ip' do
      assert Ipgeo.create(ip: '13.13.13.13')
    end

    test 'create' do
      ipgeo = Ipgeo.new(ip: '12.12.12.12', country_name: 'Chile', country_code: 'CL', latitude: '12,2,3')
      assert ipgeo.save
      ipgeo.visits << [rails_url_shortener_visits(:one_one), rails_url_shortener_visits(:one_two)]
      assert_equal 2, ipgeo.visits.count
    end

    test 'update from remote' do
      ipgeo = rails_url_shortener_ipgeos(:three)
      VCR.use_cassette("ip:#{ipgeo.ip}") do
        assert_equal 'Valparaiso', ipgeo.city_name
        ipgeo.update_from_remote
        assert_equal 'Santiago', ipgeo.city_name
      end
    end

    test 'update from remote does nothing on non-200 response' do
      ipgeo = rails_url_shortener_ipgeos(:three)
      original_city = ipgeo.city_name
      stub_request(:get, /ip-api\.com/).to_return(status: 500, body: '')
      ipgeo.update_from_remote
      assert_equal original_city, ipgeo.reload.city_name
    end

    test 'update from remote does nothing when backend is not callable' do
      ipgeo = rails_url_shortener_ipgeos(:three)
      original_city = ipgeo.city_name

      original_backend = RailsUrlShortener.ip_lookup_backend
      RailsUrlShortener.ip_lookup_backend = nil
      ipgeo.update_from_remote
      assert_equal original_city, ipgeo.reload.city_name
    ensure
      RailsUrlShortener.ip_lookup_backend = original_backend
    end
  end
end
