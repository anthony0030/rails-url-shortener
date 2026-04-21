require 'test_helper'

module RailsUrlShortener
  class ShortenableTest < ActiveSupport::TestCase
    # has_short_url dynamic methods (ONE)

    test 'url_short_url returns short url when url exists' do
      user = users(:one)
      url = Url.generate('https://example.com', owner: user, kind: 'url')
      assert url.persisted?
      assert_match(/#{url.key}/, user.url_short_url)
    end

    test 'url_short_url returns nil when no url exists' do
      user = users(:two)
      assert_nil user.url_short_url
    end

    test 'url_url returns the destination url' do
      user = users(:one)
      Url.generate('https://example.com', owner: user, kind: 'url')
      assert_equal 'https://example.com', user.url_url
    end

    test 'url_url returns nil when no url exists' do
      user = users(:two)
      assert_nil user.url_url
    end

    test 'has_url? returns true when url exists' do
      user = users(:one)
      Url.generate('https://example.com', owner: user, kind: 'url')
      assert user.has_url?
    end

    test 'has_url? returns false when no url exists' do
      user = users(:two)
      assert_not user.has_url?
    end

    # has_short_urls dynamic methods (MANY)

    setup do
      # Define a temporary model class that uses has_short_urls
      unless defined?(::ShortenableMultiTestModel)
        Object.const_set(:ShortenableMultiTestModel, Class.new(ActiveRecord::Base) {
          self.table_name = 'users'
          include RailsUrlShortener::Shortenable
          has_short_urls :links
        })
      end
    end

    test 'has_short_urls defines links association' do
      record = ShortenableMultiTestModel.find(users(:one).id)
      assert_respond_to record, :links
    end

    test 'links_short_urls returns array of short urls' do
      record = ShortenableMultiTestModel.find(users(:one).id)
      Url.generate('https://example.com/1', owner: record, kind: 'link')
      Url.generate('https://example.com/2', owner: record, kind: 'link')
      short_urls = record.links_short_urls
      assert_equal 2, short_urls.length
      short_urls.each { |u| assert_match(/https:\/\//, u) }
    end

    test 'links_urls returns array of destination urls' do
      record = ShortenableMultiTestModel.find(users(:one).id)
      Url.generate('https://example.com/a', owner: record, kind: 'link')
      Url.generate('https://example.com/b', owner: record, kind: 'link')
      urls = record.links_urls
      assert_includes urls, 'https://example.com/a'
      assert_includes urls, 'https://example.com/b'
    end

    test 'has_links? returns true when links exist' do
      record = ShortenableMultiTestModel.find(users(:one).id)
      Url.generate('https://example.com/x', owner: record, kind: 'link')
      assert record.has_links?
    end

    test 'has_links? returns false when no links exist' do
      record = ShortenableMultiTestModel.find(users(:two).id)
      assert_not record.has_links?
    end
  end
end
