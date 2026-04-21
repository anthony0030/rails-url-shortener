require 'test_helper'
require 'generators/rails_url_shortener/rails_url_shortener_generator'

module RailsUrlShortener
  class RailsUrlShortenerGeneratorTest < Rails::Generators::TestCase
    tests RailsUrlShortenerGenerator
    destination Rails.root.join('tmp/generators')

    setup :prepare_destination

    test 'generator runs without errors' do
      assert_nothing_raised do
        # create config/routes.rb in tmp/generators
        routes_file = File.join(destination_root, 'config', 'routes.rb')
        FileUtils.mkdir_p(File.dirname(routes_file))
        File.write(routes_file, "Rails.application.routes.draw do\nend")

        run_generator ['arguments']
      end

      # Verify initializer file is created at config/initializers/rails_url_shortener.rb
      assert_file 'config/initializers/rails_url_shortener.rb'

      # Verify correct entry is added to config/routes.rb
      assert_file 'config/routes.rb' do |content|
        assert_match(%r{mount RailsUrlShortener::Engine, at: '/}, content)
      end
    end

    test 'install_and_run_migrations runs rake tasks in non-test env' do
      generator = RailsUrlShortenerGenerator.new(['arguments'])

      # Track which rake tasks were called
      rake_calls = []
      generator.define_singleton_method(:rake) { |task| rake_calls << task }

      # Stub Rails.env to not be test
      original_env = Rails.env
      Rails.env = ActiveSupport::StringInquirer.new('development')

      generator.install_and_run_migrations

      assert_includes rake_calls, 'rails_url_shortener:install:migrations'
      assert_includes rake_calls, 'db:migrate'
    ensure
      Rails.env = original_env
    end
  end
end
