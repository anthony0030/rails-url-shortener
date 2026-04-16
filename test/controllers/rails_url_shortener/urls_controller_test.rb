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

    test 'show whith a not existing key' do
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
  end
end
