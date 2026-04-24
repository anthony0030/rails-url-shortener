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

    # redirect_status tests

    test 'show uses global redirect_status by default' do
      original_status = RailsUrlShortener.redirect_status
      RailsUrlShortener.redirect_status = 302
      url = Url.generate('https://example.com')
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :found
    ensure
      RailsUrlShortener.redirect_status = original_status
    end

    test 'show uses per-URL redirect_status when set' do
      original_status = RailsUrlShortener.redirect_status
      RailsUrlShortener.redirect_status = 301
      url = Url.generate('https://example.com', redirect_status: 302)
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :found
    ensure
      RailsUrlShortener.redirect_status = original_status
    end

    test 'show uses 307 redirect status when set' do
      url = Url.generate('https://example.com', redirect_status: 307)
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :temporary_redirect
    end

    test 'show uses 308 redirect status when set' do
      url = Url.generate('https://example.com', redirect_status: 308)
      get "/shortener/#{url.key}", headers: {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
      }
      assert_response :permanent_redirect
    end

    # block_root tests

    test 'root path falls through when block_root is false' do
      RailsUrlShortener.block_root = false
      get '/shortener/'
      assert_response :not_found
    ensure
      RailsUrlShortener.block_root = false
    end

    test 'root path redirects to default_redirect when block_root is true' do
      RailsUrlShortener.block_root = true
      RailsUrlShortener.default_redirect = 'https://example.com'
      get '/shortener/'
      assert_response :found
      assert_redirected_to 'https://example.com'
    ensure
      RailsUrlShortener.block_root = false
      RailsUrlShortener.default_redirect = '/'
    end

    test 'root path returns 404 when block_root is true and default_redirect is blank' do
      RailsUrlShortener.block_root = true
      RailsUrlShortener.default_redirect = nil
      get '/shortener/'
      assert_response :not_found
    ensure
      RailsUrlShortener.block_root = false
      RailsUrlShortener.default_redirect = '/'
    end

  end
end
