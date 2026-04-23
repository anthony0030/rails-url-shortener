require 'test_helper'

module RailsUrlShortener
  class UrlsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers
    include ActiveJob::TestHelper

    test 'show' do
      assert_difference 'Visit.count', 1 do
        assert_enqueued_with(job: IpCrawlerJob) do
          get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
          }
          assert_response :moved_permanently
          assert_redirected_to rails_url_shortener_urls(:one).url
        end
      end
    end

    test 'show with a not existing key' do
      assert_no_difference 'Visit.count', 1 do
        assert_no_enqueued_jobs do
          get '/shortener/noexist', headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
          }
          assert_response :moved_permanently
          assert_redirected_to RailsUrlShortener.default_redirect
        end
      end
    end

    test 'show with query params logs params in visit' do
      assert_difference 'Visit.count', 1 do
        assert_enqueued_with(job: IpCrawlerJob) do
          get "/shortener/#{rails_url_shortener_urls(:one).key}?source=qr&campaign=summer", headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
          }
          assert_response :moved_permanently
        end
      end
      visit = Visit.last
      parsed = JSON.parse(visit.params)
      assert_equal 'qr', parsed['source']
      assert_equal 'summer', parsed['campaign']
    end

    test 'show does not forward query params when forward_query_params is false' do
      RailsUrlShortener.forward_query_params = false
      get "/shortener/#{rails_url_shortener_urls(:one).key}?utm_source=twitter", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      assert_redirected_to rails_url_shortener_urls(:one).url
    end

    test 'show forwards query params when forward_query_params is true' do
      RailsUrlShortener.forward_query_params = true
      get "/shortener/#{rails_url_shortener_urls(:one).key}?utm_source=twitter&utm_campaign=spring", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      location = response.headers['Location']
      uri = URI.parse(location)
      query = Rack::Utils.parse_query(uri.query)
      assert_equal 'twitter', query['utm_source']
      assert_equal 'spring', query['utm_campaign']
    ensure
      RailsUrlShortener.forward_query_params = false
    end

    test 'show forwards query params and merges with existing destination params' do
      # Create a URL with query params already in the destination
      url = Url.generate('https://example.com/page?existing=yes')
      RailsUrlShortener.forward_query_params = true
      get "/shortener/#{url.key}?added=true", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      location = response.headers['Location']
      uri = URI.parse(location)
      query = Rack::Utils.parse_query(uri.query)
      assert_equal 'yes', query['existing']
      assert_equal 'true', query['added']
    ensure
      RailsUrlShortener.forward_query_params = false
    end

    test 'show with forward_query_params true but no query params redirects normally' do
      RailsUrlShortener.forward_query_params = true
      get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      assert_redirected_to rails_url_shortener_urls(:one).url
    ensure
      RailsUrlShortener.forward_query_params = false
    end

    test 'per-URL forward_query_params true overrides global false' do
      url = Url.generate('https://example.com/page', forward_query_params: true)
      get "/shortener/#{url.key}?source=email", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      location = response.headers['Location']
      uri = URI.parse(location)
      query = Rack::Utils.parse_query(uri.query)
      assert_equal 'email', query['source']
    end

    test 'per-URL forward_query_params false overrides global true' do
      RailsUrlShortener.forward_query_params = true
      url = Url.generate('https://example.com/page', forward_query_params: false)
      get "/shortener/#{url.key}?source=email", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      assert_redirected_to 'https://example.com/page'
    ensure
      RailsUrlShortener.forward_query_params = false
    end

    test 'per-URL forward_query_params nil falls back to global setting' do
      RailsUrlShortener.forward_query_params = true
      url = Url.generate('https://example.com/page', forward_query_params: nil)
      get "/shortener/#{url.key}?source=email", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :moved_permanently
      location = response.headers['Location']
      uri = URI.parse(location)
      query = Rack::Utils.parse_query(uri.query)
      assert_equal 'email', query['source']
    ensure
      RailsUrlShortener.forward_query_params = false
    end

    # password protection tests

    test 'show returns 401 for password-protected URL without credentials' do
      url = Url.generate('https://example.com', password: 'secret123')
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :unauthorized
      assert_equal 'Basic realm="Password Required"', response.headers['WWW-Authenticate']
    end

    test 'show returns 401 for password-protected URL with wrong password' do
      url = Url.generate('https://example.com', password: 'secret123')
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials('', 'wrongpass')
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Authorization': credentials
      }
      assert_response :unauthorized
    end

    test 'show redirects for password-protected URL with correct password' do
      url = Url.generate('https://example.com', password: 'secret123')
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials('', 'secret123')
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Authorization': credentials
      }
      assert_response :moved_permanently
      assert_redirected_to 'https://example.com'
    end

    test 'show redirects for password-protected URL with any username and correct password' do
      url = Url.generate('https://example.com', password: 'secret123')
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials('anyuser', 'secret123')
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Authorization': credentials
      }
      assert_response :moved_permanently
      assert_redirected_to 'https://example.com'
    end

    test 'show with password-protected URL and forward_query_params works after auth' do
      url = Url.generate('https://example.com/page', password: 'secret123', forward_query_params: true)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials('', 'secret123')
      get "/shortener/#{url.key}?source=email", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Authorization': credentials
      }
      assert_response :moved_permanently
      location = response.headers['Location']
      uri = URI.parse(location)
      query = Rack::Utils.parse_query(uri.query)
      assert_equal 'email', query['source']
    end

    # tracked tests

    test 'show does not create visit when tracked is false' do
      url = Url.generate('https://example.com', tracked: false)
      assert_no_difference 'Visit.count' do
        get "/shortener/#{url.key}", headers: {
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
        }
        assert_response :moved_permanently
        assert_redirected_to 'https://example.com'
      end
    end

    test 'show creates visit when tracked is true' do
      url = Url.generate('https://example.com')
      assert_difference 'Visit.count', 1 do
        assert_enqueued_with(job: IpCrawlerJob) do
          get "/shortener/#{url.key}", headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
          }
          assert_response :moved_permanently
          assert_redirected_to 'https://example.com'
        end
      end
    end

    # host constraint tests

    test 'show works when enforce_host_constraint is false regardless of host' do
      RailsUrlShortener.enforce_host_constraint = false
      get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'HOST': 'random.host.com'
      }
      assert_response :moved_permanently
    ensure
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'show works when enforce_host_constraint is true and host matches' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'www.example.com'
      get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'HOST': 'www.example.com'
      }
      assert_response :moved_permanently
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'show returns 404 when enforce_host_constraint is true and host does not match' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com'
      RailsUrlShortener.custom_hosts = {}
      get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'HOST': 'evil.com'
      }
      assert_response :not_found
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.enforce_host_constraint = false
    end

    test 'show works when enforce_host_constraint is true and host matches custom_host' do
      RailsUrlShortener.enforce_host_constraint = true
      original_host = RailsUrlShortener.host
      RailsUrlShortener.host = 'short.example.com'
      RailsUrlShortener.custom_hosts = { 'marketing' => 'mkt.example.com' }
      get "/shortener/#{rails_url_shortener_urls(:one).key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'HOST': 'mkt.example.com'
      }
      assert_response :moved_permanently
    ensure
      RailsUrlShortener.host = original_host
      RailsUrlShortener.custom_hosts = {}
      RailsUrlShortener.enforce_host_constraint = false
    end
  end
end
