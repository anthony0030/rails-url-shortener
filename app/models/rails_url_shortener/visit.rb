# frozen_string_literal: true

# == Schema Information
#
# Table name: rails_url_shortener_visits
#
#  id               :integer          not null, primary key
#  url_id           :integer
#  ip               :string
#  browser          :string
#  browser_version  :string
#  platform         :string
#  platform_version :string
#  bot              :boolean
#  user_agent       :string
#  meta             :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  ipgeo_id         :integer
#  referer          :string           default("")
#  params           :text
#
module RailsUrlShortener
  require 'json'
  class Visit < ApplicationRecord
    belongs_to :url
    belongs_to :ipgeo, optional: true

    ##
    # Parse a request information and save
    #
    # Return boolean
    # rubocop:disable Metrics/AbcSize
    def self.parse_and_save(url, request)
      return false unless RailsUrlShortener.save_visits

      browser(request)
      return false if !RailsUrlShortener.save_bots_visits && @browser.bot?

      visit = Visit.create(
        url: url,
        ip: request.ip,
        browser: @browser.name,
        browser_version: @browser.full_version,
        platform: @browser.platform.name,
        platform_version: @browser.platform.version,
        bot: @browser.bot?,
        user_agent: request.headers['User-Agent'],
        referer: request.headers['Referer'],
        params: request.query_parameters.except(:key).to_json.presence
      )

      IpCrawlerJob.perform_later(visit)
      visit
    end
    # rubocop:enable Metrics/AbcSize

    def self.browser(request)
      @browser = Browser.new(request.headers['User-Agent'])
    end
  end
end
