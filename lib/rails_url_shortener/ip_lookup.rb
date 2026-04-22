# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

module RailsUrlShortener
  module IpLookup
    # Built-in backend for ip-api.com (free tier, no key required; pro tier uses key)
    IP_API_COM = lambda { |ip_address, api_key|
      provider = 'ip-api.com'
      base = api_key ? 'https://pro.ip-api.com' : 'http://ip-api.com'
      url = "#{base}/json/#{ip_address}"
      url += '?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query' # rubocop:disable Layout/LineLength
      url += "&key=#{api_key}" if api_key
      response = HTTP.get(url)

      return nil unless response.code == 200

      data = JSON.parse(response.body)

      {
        as: data['as'],
        asname: data['asname'],
        # asn: data['asn'], # ! NOT avialible
        city_name: data['city'],
        continent_code: data['continentCode'],
        continent_name: data['continent'],
        country_code: data['countryCode'],
        # country_code_iso3: data['countryCodeIso3'], # ! NOT avialible
        # country_area: data['country_area'], # ! NOT avialible
        # country_calling_code: data['country_calling_code'], # ! NOT avialible
        # country_capital_name: data['country_capital'], # ! NOT avialible
        country_name: data['country'],
        # country_population: data['country_population'], # ! NOT avialible
        # country_tld: data['country_tld'], # ! NOT avialible
        currency_code: data['currency'],
        # currency_name: data['currencyName'], # ! NOT avialible
        district: data['district'],
        host_name: data['reverse'],
        hosting: data['hosting'],
        # in_eu: data['in_eu'], # ! NOT avialible
        ip: ip_address,
        # ip_version: data['version'], # ! NOT avialible
        isp: data['isp'],
        # languages: data['languages'], # ! NOT avialible
        latitude: data['lat'],
        longitude: data['lon'],
        mobile: data['mobile'],
        # network: data['network'], # ! NOT avialible
        offset: data['offset'],
        org: data['org'],
        provider: provider,
        proxy: data['proxy'],
        region_code: data['region'],
        region_name: data['regionName'],
        timezone: data['timezone'],
        # utc_offset: data['utc_offset'],
        zip_code: data['zip'],
      }
    }

    # Built-in backend for ipapi.co (free tier or with key)
    IPAPI_CO = lambda { |ip_address, api_key|
      provider = 'ipapi.co'
      url = "https://ipapi.co/#{ip_address}/json/"
      url += "?key=#{api_key}" if api_key.present?
      response = HTTP.get(url)

      return nil unless response.code == 200

      data = JSON.parse(response.body)
      {
        as: data['as'],
        # # asname: data['asname'], # ! NOT avialible
        asn: data['asn'],
        city_name: data['city'],
        continent_code: data['continent_code'],
        # continent_name: data['continent'], # ! NOT avialible
        country_area: data['country_area'],
        country_calling_code: data['country_calling_code'],
        country_capital_name: data['country_capital'],
        country_code: data['country_code'],
        country_code_iso3: data['country_code_iso3'],
        country_name: data['country_name'],
        country_population: data['country_population'],
        country_tld: data['country_tld'],
        currency_code: data['currency'],
        currency_name: data['currency_name'],
        # district: data['district'], # ! NOT avialible
        # host_name: data['reverse'], # ! NOT avialible
        # hosting: data['hosting'], # ! NOT avialible
        in_eu: data['in_eu'],
        ip: ip_address, # data['ip'] is also avialible
        ip_version: data['version'],
        # isp: data['isp'], # ! NOT avialible
        languages: data['languages'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        # mobile: data['mobile'], # ! NOT avialible
        network: data['network'],
        org: data['org'],
        # # offset: data['offset'], # ! NOT avialible
        provider: provider,
        # proxy: data['proxy'], # ! NOT avialible
        region_code: data['region_code'],
        region_name: data['region'],
        timezone: data['timezone'],
        utc_offset: data['utc_offset'],
        zip_code: data['postal'],
      }
    }
  end
end

# rubocop:enable Metrics/BlockLength
