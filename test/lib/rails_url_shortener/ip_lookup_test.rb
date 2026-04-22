# frozen_string_literal: true

require 'test_helper'

module RailsUrlShortener
  class IpLookupTest < ActiveSupport::TestCase
    # --- IP_API_COM ---

    test 'IP_API_COM returns mapped hash on 200' do
      body = {
        'status' => 'success', 'country' => 'Chile', 'countryCode' => 'CL',
        'region' => 'RM', 'regionName' => 'Santiago Metropolitan', 'city' => 'Santiago',
        'district' => '', 'zip' => '8320000', 'lat' => -33.4513, 'lon' => -70.6653,
        'timezone' => 'America/Santiago', 'offset' => -14_400, 'currency' => 'CLP',
        'isp' => 'GTD', 'org' => 'GTD', 'as' => 'AS22047 GTD',
        'asname' => 'GTD', 'reverse' => '', 'mobile' => false, 'proxy' => false,
        'hosting' => false, 'continent' => 'South America', 'continentCode' => 'SA',
        'query' => '66.90.76.179'
      }.to_json

      stub_request(:get, /ip-api\.com/).to_return(status: 200, body: body)

      result = IpLookup::IP_API_COM.call('66.90.76.179', nil)

      assert_kind_of Hash, result
      assert_equal 'Chile', result[:country_name]
      assert_equal 'Santiago', result[:city_name]
      assert_equal 'ip-api.com', result[:provider]
      assert_equal 'SA', result[:continent_code]
    end

    test 'IP_API_COM uses pro endpoint when api_key is provided' do
      body = { 'status' => 'success', 'country' => 'Chile', 'countryCode' => 'CL',
               'region' => 'RM', 'regionName' => 'Santiago Metropolitan', 'city' => 'Santiago',
               'district' => '', 'zip' => '', 'lat' => -33.45, 'lon' => -70.66,
               'timezone' => 'America/Santiago', 'offset' => -14_400, 'currency' => 'CLP',
               'isp' => 'GTD', 'org' => 'GTD', 'as' => 'AS22047', 'asname' => 'GTD',
               'reverse' => '', 'mobile' => false, 'proxy' => false, 'hosting' => false,
               'continent' => 'South America', 'continentCode' => 'SA',
               'query' => '1.2.3.4' }.to_json

      stub_request(:get, %r{pro\.ip-api\.com.*key=my_key}).to_return(status: 200, body: body)

      result = IpLookup::IP_API_COM.call('1.2.3.4', 'my_key')

      assert_kind_of Hash, result
      assert_equal 'Chile', result[:country_name]
    end

    test 'IP_API_COM returns nil on non-200 response' do
      stub_request(:get, /ip-api\.com/).to_return(status: 429, body: '')

      result = IpLookup::IP_API_COM.call('1.2.3.4', nil)

      assert_nil result
    end

    # --- IPAPI_CO ---

    test 'IPAPI_CO returns mapped hash on 200' do
      body = {
        'ip' => '8.8.8.8', 'version' => 'IPv4', 'network' => '8.8.8.0/24',
        'city' => 'Mountain View', 'region_code' => 'CA', 'region' => 'California',
        'country_code' => 'US', 'country_code_iso3' => 'USA', 'country_name' => 'United States',
        'country_capital' => 'Washington', 'country_tld' => '.us', 'continent_code' => 'NA',
        'in_eu' => false, 'postal' => '94035', 'latitude' => 37.386, 'longitude' => -122.0838,
        'timezone' => 'America/Los_Angeles', 'utc_offset' => '-0700',
        'country_calling_code' => '+1', 'currency' => 'USD', 'currency_name' => 'Dollar',
        'languages' => 'en-US,es-US', 'country_area' => 9_629_091.0,
        'country_population' => 310_232_863, 'asn' => 'AS15169', 'org' => 'Google LLC',
        'as' => 'AS15169 Google LLC'
      }.to_json

      stub_request(:get, %r{ipapi\.co/8\.8\.8\.8/json}).to_return(status: 200, body: body)

      result = IpLookup::IPAPI_CO.call('8.8.8.8', nil)

      assert_kind_of Hash, result
      assert_equal 'United States', result[:country_name]
      assert_equal 'Mountain View', result[:city_name]
      assert_equal 'ipapi.co', result[:provider]
      assert_equal 'NA', result[:continent_code]
      assert_equal 'IPv4', result[:ip_version]
      assert_equal '8.8.8.8', result[:ip]
    end

    test 'IPAPI_CO appends key when api_key is provided' do
      body = { 'ip' => '1.2.3.4', 'city' => 'Test', 'region_code' => 'T',
               'region' => 'Test', 'country_code' => 'US', 'country_name' => 'United States',
               'latitude' => 0, 'longitude' => 0, 'timezone' => 'UTC' }.to_json

      stub_request(:get, %r{ipapi\.co/1\.2\.3\.4/json/\?key=secret}).to_return(status: 200, body: body)

      result = IpLookup::IPAPI_CO.call('1.2.3.4', 'secret')

      assert_kind_of Hash, result
      assert_equal 'United States', result[:country_name]
    end

    test 'IPAPI_CO returns nil on non-200 response' do
      stub_request(:get, /ipapi\.co/).to_return(status: 403, body: '')

      result = IpLookup::IPAPI_CO.call('1.2.3.4', nil)

      assert_nil result
    end
  end
end
