# frozen_string_literal: true

require 'rails/generators'

class RailsUrlShortener::ExtensionsGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_extension_files
    template 'url_extension.rb.tt',   'app/models/concerns/rails_url_shortener/url_extension.rb'
    template 'visit_extension.rb.tt', 'app/models/concerns/rails_url_shortener/visit_extension.rb'
    template 'ipgeo_extension.rb.tt', 'app/models/concerns/rails_url_shortener/ipgeo_extension.rb'
  end
end
