# == Schema Information
#
# Table name: rails_url_shortener_urls
#
#  id         :integer          not null, primary key
#  category   :string
#  expires_at :datetime
#  key        :string(10)       not null
#  kind       :string
#  owner_type :string
#  paused     :boolean          default(FALSE), not null
#  starts_at  :datetime
#  url        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :integer
#
# Indexes
#
#  index_rails_url_shortener_urls_on_owner  (owner_type,owner_id)
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
  end
end
