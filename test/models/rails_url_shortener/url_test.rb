# == Schema Information
#
# Table name: rails_url_shortener_urls
#
#  id                   :integer          not null, primary key
#  owner_type           :string
#  owner_id             :integer
#  url                  :text             not null
#  key                  :string(10)       not null
#  category             :string
#  expires_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  kind                 :string
#  starts_at            :datetime
#  paused               :boolean          default(FALSE), not null
#  forward_query_params :boolean
#
require 'test_helper'

module RailsUrlShortener
  class UrlTest < ActiveSupport::TestCase
    ##
    # Test basic of model url
    #
    test 'create' do
      url = Url.new(
        url: 'https://api.rubyonrails.org/v4.1.9/classes/Rails/Generators/Migration.html#method-i-migration_template',
        key: 'as12as',
        category: 'docs'
      )
      assert url.save
      url.visits << [rails_url_shortener_visits(:one_one), rails_url_shortener_visits(:one_two)]
      assert_equal url.visits.count, 2
    end

    test 'minimun validation key' do
      url = Url.new(
        url: 'https://api.rubyonrails.org/v4.1.9/classes/Rails/Generators/Migration.html#method-i-migration_template',
        key: 'AA',
        category: 'docs'
      )
      assert_not url.save
      assert_equal url.errors.first.attribute, :key
      assert_equal url.errors.first.type, :too_short
    end

    test 'valid url' do
      url = Url.new(
        url: 'htt://api.rubyonrails.org',
        key: 'AABB123',
        category: 'docs'
      )
      assert_not url.save
      assert_equal url.errors.first.attribute, :url
      url.url = 'https:://fuckgoogle.com'
      assert url.save
    end

    test 'find by key!' do
      assert_equal rails_url_shortener_urls(:one), Url.find_url_by_key!(rails_url_shortener_urls(:one).key)
    end

    test 'find by key' do
      assert_equal RailsUrlShortener.default_redirect, Url.find_url_by_key('not_exist').url
    end

    test 'basic generate key' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', expires_at: Time.now + 1.hour)
      assert url
      assert_equal url.key, Url.last.key
      assert_equal url.url, 'https://github.com/a-chacon/rails_url_shortener'
      assert_equal url.expires_at.utc.ceil, (Time.now.utc.ceil + 1.hour)
    end

    test 'generate with starts_at' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', starts_at: Time.now + 1.hour)
      assert url.persisted?
      assert_equal url.starts_at.utc.ceil, (Time.now.utc + 1.hour).ceil
    end

    test 'find by key! excludes not yet started urls' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', starts_at: Time.now + 1.hour)
      assert_raises(ActiveRecord::RecordNotFound) do
        Url.find_url_by_key!(url.key)
      end
    end

    test 'find by key! includes started urls' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', starts_at: Time.now - 1.hour)
      assert_equal url, Url.find_url_by_key!(url.key)
    end

    test 'find by key returns default for not yet started urls' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', starts_at: Time.now + 1.hour)
      result = Url.find_url_by_key(url.key)
      assert_equal RailsUrlShortener.default_redirect, result.url
    end

    test 'custom key generate' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'asd123')
      assert url
      assert_equal url.key, 'asd123'
      assert_equal url.url, 'https://github.com/a-chacon/rails_url_shortener'
    end

    test 'custom key and user related' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'asd123', owner: users(:one))
      assert url
      assert_equal url.key, 'asd123'
      assert_equal url.url, 'https://github.com/a-chacon/rails_url_shortener'
      assert_equal url.owner, users(:one)
    end

    test 'error if the custom key exists' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.errors.first.attribute, :key
      assert_equal url.errors.first.type, :taken
    end

    test 'to short url without secure option' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.to_short_url, "https://#{RailsUrlShortener.host}/shortener/aE1111"
    end

    test 'to short url with secure true' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.to_short_url(secure: true), "https://#{RailsUrlShortener.host}/shortener/aE1111"
    end

    test 'to short url with secure false' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.to_short_url(secure: false), "http://#{RailsUrlShortener.host}/shortener/aE1111"
    end

    test 'to short url with params' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.to_short_url(params: { source: 'qr' }), "https://#{RailsUrlShortener.host}/shortener/aE1111?source=qr"
    end

    test 'to short url with multiple params' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      short = url.to_short_url(params: { source: 'nfc', campaign: 'summer' })
      uri = URI.parse(short)
      parsed_params = Rack::Utils.parse_query(uri.query)
      assert_equal parsed_params['source'], 'nfc'
      assert_equal parsed_params['campaign'], 'summer'
    end

    test 'to short url with empty params' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'aE1111')
      assert_equal url.to_short_url(params: {}), "https://#{RailsUrlShortener.host}/shortener/aE1111"
    end

    test 'paused url is not found by find_url_by_key!' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.pause!
      assert_raises(ActiveRecord::RecordNotFound) do
        Url.find_url_by_key!(url.key)
      end
    end

    test 'paused url returns default redirect via find_url_by_key' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.pause!
      result = Url.find_url_by_key(url.key)
      assert_equal RailsUrlShortener.default_redirect, result.url
    end

    test 'pause! sets paused to true' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      assert_not url.paused
      url.pause!
      assert url.reload.paused
    end

    test 'unpause! sets paused to false' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', paused: true)
      assert url.paused
      url.unpause!
      assert_not url.reload.paused
    end

    test 'unpaused url is found by find_url_by_key!' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.pause!
      url.unpause!
      assert_equal url, Url.find_url_by_key!(url.key)
    end

    test 'paused overrides starts_at and expires_at' do
      url = Url.generate(
        'https://github.com/a-chacon/rails_url_shortener',
        starts_at: Time.now - 1.hour,
        expires_at: Time.now + 1.hour,
        paused: true
      )
      assert_raises(ActiveRecord::RecordNotFound) do
        Url.find_url_by_key!(url.key)
      end
    end

    test 'status returns :paused when paused' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.pause!
      assert_equal :paused, url.status
    end

    test 'status returns :expired when past expires_at' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', expires_at: Time.now - 1.hour)
      assert_equal :expired, url.status
    end

    test 'status returns :upcoming when before starts_at' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', starts_at: Time.now + 1.hour)
      assert_equal :upcoming, url.status
    end

    test 'status returns :active for normal url' do
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      assert_equal :active, url.status
    end

    test 'status returns :active when within starts_at and expires_at' do
      url = Url.generate(
        'https://github.com/a-chacon/rails_url_shortener',
        starts_at: Time.now - 1.hour,
        expires_at: Time.now + 1.hour
      )
      assert_equal :active, url.status
    end

    test 'status paused takes priority over expired' do
      url = Url.generate(
        'https://github.com/a-chacon/rails_url_shortener',
        expires_at: Time.now - 1.hour,
        paused: true
      )
      assert_equal :paused, url.status
    end

    test 'status paused takes priority over upcoming' do
      url = Url.generate(
        'https://github.com/a-chacon/rails_url_shortener',
        starts_at: Time.now + 1.hour,
        paused: true
      )
      assert_equal :paused, url.status
    end

    test 'status returns :paused when within starts_at and expires_at and paused' do
      url = Url.generate(
        'https://github.com/a-chacon/rails_url_shortener',
        starts_at: Time.now - 1.hour,
        expires_at: Time.now + 1.hour,
        paused: true
      )
      assert_equal :paused, url.status
    end

    # disable_url_key_updates tests

    test 'key can be updated when disable_url_key_updates is false' do
      RailsUrlShortener.disable_url_key_updates = false
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      original_key = url.key
      url.key = 'newkey1'
      assert url.save
      assert_equal 'newkey1', url.reload.key
      assert_not_equal original_key, url.key
    end

    test 'key cannot be updated when disable_url_key_updates is true' do
      RailsUrlShortener.disable_url_key_updates = true
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      original_key = url.key
      url.key = 'newkey2'
      assert_not url.save
      assert_includes url.errors[:key], 'cannot be changed after creation'
      assert_equal original_key, url.reload.key
    ensure
      RailsUrlShortener.disable_url_key_updates = false
    end

    test 'other attributes can be updated when disable_url_key_updates is true' do
      RailsUrlShortener.disable_url_key_updates = true
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.url = 'https://example.com'
      assert url.save
      assert_equal 'https://example.com', url.reload.url
    ensure
      RailsUrlShortener.disable_url_key_updates = false
    end

    test 'new url can still be created when disable_url_key_updates is true' do
      RailsUrlShortener.disable_url_key_updates = true
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      assert url.persisted?
      assert url.key.present?
    ensure
      RailsUrlShortener.disable_url_key_updates = false
    end

    test 'custom key on create works when disable_url_key_updates is true' do
      RailsUrlShortener.disable_url_key_updates = true
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener', key: 'custom1')
      assert url.persisted?
      assert_equal 'custom1', url.key
    ensure
      RailsUrlShortener.disable_url_key_updates = false
    end

    test 'generate_key increases key_length after 10 collisions' do
      # Create a url that will collide
      original_length = RailsUrlShortener.key_length

      url = Url.new(url: 'https://example.com')
      url.key_length = original_length

      # Stub key_candidate to return colliding keys for first 10 attempts, then a unique one
      call_count = 0
      existing_keys = Url.pluck(:key)
      collide_key = existing_keys.first

      url.define_singleton_method(:key_candidate) do
        call_count += 1
        if call_count <= 10
          collide_key
        else
          'unique_key'
        end
      end

      url.send(:generate_key)
      assert_equal original_length + 1, url.key_length
      assert_equal 'unique_key', url.key
    end

    test 'prevent_key_change allows save when key is unchanged and feature enabled' do
      RailsUrlShortener.disable_url_key_updates = true
      url = Url.generate('https://github.com/a-chacon/rails_url_shortener')
      url.url = 'https://example.com/updated'
      assert url.save
      assert_equal 'https://example.com/updated', url.reload.url
    ensure
      RailsUrlShortener.disable_url_key_updates = false
    end

    test 'find_url_by_key uses fallback slash when default_redirect is nil' do
      original = RailsUrlShortener.default_redirect
      RailsUrlShortener.default_redirect = nil
      result = Url.find_url_by_key('nonexistent_key')
      assert_equal '/', result.url
    ensure
      RailsUrlShortener.default_redirect = original
    end

    # password protection tests

    test 'generate with password sets password_digest' do
      url = Url.generate('https://example.com', password: 'secret123')
      assert url.persisted?
      assert url.password_digest.present?
    end

    test 'generate without password leaves password_digest nil' do
      url = Url.generate('https://example.com')
      assert url.persisted?
      assert_nil url.password_digest
    end

    test 'password_protected? returns true when password is set' do
      url = Url.generate('https://example.com', password: 'secret123')
      assert url.password_protected?
    end

    test 'password_protected? returns false when no password' do
      url = Url.generate('https://example.com')
      assert_not url.password_protected?
    end

    test 'authenticate returns url with correct password' do
      url = Url.generate('https://example.com', password: 'secret123')
      assert url.authenticate('secret123')
    end

    test 'authenticate returns false with wrong password' do
      url = Url.generate('https://example.com', password: 'secret123')
      assert_not url.authenticate('wrong')
    end

    # tracked tests

    test 'generate defaults tracked to true' do
      url = Url.generate('https://example.com')
      assert url.persisted?
      assert url.tracked
    end

    test 'generate with tracked false' do
      url = Url.generate('https://example.com', tracked: false)
      assert url.persisted?
      assert_not url.tracked
    end

    test 'find_url_by_key! creates visit when tracked is true' do
      url = Url.generate('https://example.com')
      assert_difference 'Visit.count', 1 do
        Url.find_url_by_key!(url.key, request: ActionDispatch::TestRequest.create(
          'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
        ))
      end
    end

    test 'find_url_by_key! does not create visit when tracked is false' do
      url = Url.generate('https://example.com', tracked: false)
      assert_no_difference 'Visit.count' do
        Url.find_url_by_key!(url.key, request: ActionDispatch::TestRequest.create(
          'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
        ))
      end
    end

    test 'find_url_by_key does not create visit when tracked is false' do
      url = Url.generate('https://example.com', tracked: false)
      assert_no_difference 'Visit.count' do
        Url.find_url_by_key(url.key, request: ActionDispatch::TestRequest.create(
          'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
        ))
      end
    end

    # custom_host tests

    test 'generate with custom_host stores the key' do
      url = Url.generate('https://example.com', custom_host: 'marketing')
      assert url.persisted?
      assert_equal 'marketing', url.custom_host
    end

    test 'generate without custom_host leaves it nil' do
      url = Url.generate('https://example.com')
      assert url.persisted?
      assert_nil url.custom_host
    end

    test 'to_short_url resolves custom_host key via custom_hosts mapping' do
      RailsUrlShortener.custom_hosts = { 'marketing' => 'mkt.example.com' }
      url = Url.generate('https://example.com', custom_host: 'marketing')
      assert_includes url.to_short_url, 'mkt.example.com'
      assert_not_includes url.to_short_url, RailsUrlShortener.host
    ensure
      RailsUrlShortener.custom_hosts = {}
    end

    test 'to_short_url falls back to global host when custom_host key is not in mapping' do
      RailsUrlShortener.custom_hosts = {}
      url = Url.generate('https://example.com', custom_host: 'unknown')
      assert_includes url.to_short_url, RailsUrlShortener.host
    ensure
      RailsUrlShortener.custom_hosts = {}
    end

    test 'to_short_url falls back to global host when custom_host is nil' do
      url = Url.generate('https://example.com')
      assert_includes url.to_short_url, RailsUrlShortener.host
    end

    test 'to_short_url falls back to global host when custom_host is blank' do
      url = Url.generate('https://example.com', custom_host: '')
      assert_includes url.to_short_url, RailsUrlShortener.host
    end

    # resolve_host tests

    test 'resolve_host returns mapped host for known key' do
      RailsUrlShortener.custom_hosts = { 'support' => 'help.example.com' }
      assert_equal 'help.example.com', RailsUrlShortener.resolve_host('support')
    ensure
      RailsUrlShortener.custom_hosts = {}
    end

    test 'resolve_host returns mapped host when mapping keys are symbols' do
      RailsUrlShortener.custom_hosts = { support: 'help.example.com' }
      assert_equal 'help.example.com', RailsUrlShortener.resolve_host('support')
    ensure
      RailsUrlShortener.custom_hosts = {}
    end

    test 'resolve_host returns global host for unknown key' do
      RailsUrlShortener.custom_hosts = {}
      assert_equal RailsUrlShortener.host, RailsUrlShortener.resolve_host('unknown')
    end

    test 'resolve_host returns global host for nil' do
      assert_equal RailsUrlShortener.host, RailsUrlShortener.resolve_host(nil)
    end

    test 'resolve_host returns global host for blank string' do
      assert_equal RailsUrlShortener.host, RailsUrlShortener.resolve_host('')
    end
  end
end
