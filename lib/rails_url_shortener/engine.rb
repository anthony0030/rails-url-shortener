# frozen_string_literal: true

module RailsUrlShortener
  class Engine < ::Rails::Engine
    isolate_namespace RailsUrlShortener
    require 'browser'
    require 'http'

    # Auto-include extension modules defined by the host app.
    # If RailsUrlShortener::UrlExtension (or VisitExtension, IpgeoExtension)
    # is defined, it will be included into the corresponding model automatically.
    config.to_prepare do
      %i[Url Visit Ipgeo].each do |model|
        extension = :"#{model}Extension"

        next unless RailsUrlShortener.const_defined?(extension, false)

        model_class = RailsUrlShortener.const_get(model)
        extension_module = RailsUrlShortener.const_get(extension)
        model_class.include(extension_module) unless model_class < extension_module
      end
    end
  end
end
