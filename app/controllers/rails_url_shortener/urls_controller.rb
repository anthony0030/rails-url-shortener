# frozen_string_literal: true

module RailsUrlShortener
  class UrlsController < ActionController::Metal
    include ActionController::StrongParameters
    include ActionController::Redirecting
    include ActionController::Instrumentation
    include Rails.application.routes.url_helpers

    def show
      # find, if you pass the request then this is saved
      url = Url.find_url_by_key(params[:key], request: request)
      destination = url.url

      if url.forward_query_params.nil? ? RailsUrlShortener.forward_query_params : url.forward_query_params
        query = request.query_parameters.except(:key)
        if query.any?
          uri = URI.parse(destination)
          existing = URI.decode_www_form(uri.query || '')
          uri.query = URI.encode_www_form(existing + query.to_a)
          destination = uri.to_s
        end
      end

      redirect_to destination, status: :moved_permanently
    end
  end
end
