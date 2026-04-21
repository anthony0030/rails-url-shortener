require 'test_helper'

class RailsUrlShortenerTest < ActiveSupport::TestCase
  test 'it has a version number' do
    assert RailsUrlShortener::VERSION
  end

  test 'legacy has_short_urls defines has_many urls association' do
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      extend RailsUrlShortener::Model
      has_short_urls
    end
    record = klass.find(ActiveRecord::FixtureSet.identify(:one))
    assert_respond_to record, :urls
    assert_equal 'has_many', record.class.reflect_on_association(:urls).macro.to_s
  end
end
