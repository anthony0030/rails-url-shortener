# frozen_string_literal: true

module RailsUrlShortener
  class UrlsController < ActionController::Metal
    include ActionController::StrongParameters
    include ActionController::Redirecting
    include ActionController::Instrumentation
    include ActionController::Head
    include Rails.application.routes.url_helpers

    def show
      # find, if you pass the request then this is saved
      url = Url.find_url_by_key(params[:key], request: request)
      destination = url.url

      if url.password_protected?
        password = extract_basic_auth_password
        unless password && url.authenticate(password)
          self.status = 401
          self.headers['WWW-Authenticate'] = 'Basic realm="Password Required"'
          self.content_type = 'text/plain'
          self.response_body = ['Unauthorized']
          return
        end
      end

      if url.forward_query_params.nil? ? RailsUrlShortener.forward_query_params : url.forward_query_params
        query = request.query_parameters.except(:key)
        if query.any?
          uri = URI.parse(destination)
          existing = URI.decode_www_form(uri.query || '')
          uri.query = URI.encode_www_form(existing + query.to_a)
          destination = uri.to_s
        end
      end

      redirect_to destination, status: url.effective_redirect_status
    end

    private

    def extract_basic_auth_password
      auth = request.headers['Authorization']
      return nil unless auth&.start_with?('Basic ')

      decoded = Base64.decode64(auth.split(' ', 2).last)
      _username, password = decoded.split(':', 2)
      password
    end
  end
end
