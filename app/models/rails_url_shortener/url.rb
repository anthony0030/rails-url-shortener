# frozen_string_literal: true

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
module RailsUrlShortener
  class Url < ApplicationRecord
    has_secure_password validations: false

    # variables
    attr_accessor :generating_retries, :key_length

    # relations
    belongs_to :owner, polymorphic: true, optional: true
    has_many :visits, dependent: :nullify

    # validations
    validates :key, presence: true, length: { minimum: RailsUrlShortener.minimum_key_length }, uniqueness: true
    validates :url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
    validates :kind, presence: true, if: :owned?

    # exclude records where starts_at is set and is in the future
    scope :started, -> { where(arel_table[:starts_at].eq(nil).or(arel_table[:starts_at].lteq(::Time.current))) }

    # exclude records in which expiration time is set and expiration time is greater than current time
    scope :unexpired, -> { where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].gt(::Time.current))) }

    scope :paused,   -> { where(paused: true) }
    scope :unpaused, -> { where(paused: false) }

    scope :owned,   -> { where.not(owner_id: nil).where.not(owner_type: nil) }
    scope :unowned, -> { where(owner_id: nil, owner_type: nil) }

    scope :invalid_owner, -> { where.not(owner_id: nil).where(owner_type: nil).or(where(owner_id: nil).where.not(owner_type: nil)) }

    # combine all scopes for active URLs
    scope :active, -> { started.unexpired.unpaused }

    # combine active + owned
    scope :active_owned, -> { active.owned }
    scope :active_unowned, -> { active.unowned }

    after_initialize :set_attr
    # callbacks
    before_validation :generate_key
    before_update :prevent_key_change, if: -> { RailsUrlShortener.disable_url_key_updates }

    ##
    # set default instance variables values
    def set_attr
      @generating_retries = 0
      @key_length = RailsUrlShortener.key_length
    end

    ##
    # create a url object with the given params
    #
    # if something is wrong return the object with errors

    def self.generate(url, owner: nil, key: nil, kind: nil, starts_at: nil, expires_at: nil, paused: false, category: nil, forward_query_params: nil, password: nil)
      create(
        url: url,
        owner: owner,
        key: key,
        kind: kind,
        starts_at: starts_at,
        expires_at: expires_at,
        paused: paused,
        category: category,
        forward_query_params: forward_query_params,
        password: password
      )
    end

    ##
    # find a Url object by the key param
    #
    # if the Url is not found an exception is raised
    def self.find_url_by_key!(key, request: nil)
      # Get the token if active (started and not expired)
      url = Url.active.find_by!(key: key)
      Visit.parse_and_save(url, request) unless request.nil?
      url
    end

    ##
    # find a Url object by the key param
    #
    # if the Url is not found the exception is rescue and
    # return a new url object with the default url

    def self.find_url_by_key(key, request: nil)
      find_url_by_key!(key, request: request)
    rescue ActiveRecord::RecordNotFound
      Url.new(
        url: RailsUrlShortener.default_redirect || '/',
        key: 'none'
      )
    end

    ##
    # Function for help to build the full short url when you have the object.
    #
    def to_short_url(secure: true, params: {})
      protocol = secure ? 'https://' : 'http://'
      host = RailsUrlShortener.host
      path = Rails.application.routes.url_helpers.rails_url_shortener_path

      base = [protocol, host, path, "/#{key}"].reject { _1 == '/' }.join
      params.any? ? "#{base}?#{params.to_query}" : base
    end

    ##
    # Function to determin if there is an owner
    #
    def owned?
      owner_type.present? && owner_id.present?
    end

    ##
    # Pause this URL, preventing it from resolving
    #
    def pause!
      update!(paused: true)
    end

    ##
    # Unpause this URL, allowing it to resolve again
    #
    def unpause!
      update!(paused: false)
    end

    ##
    # Returns true if this URL requires a password to access
    #
    def password_protected?
      password_digest.present?
    end

    ##
    # Returns the current status of the URL as a symbol.
    #
    # :paused   - URL is manually paused
    # :expired  - URL has passed its expires_at time
    # :upcoming - URL has not yet reached its starts_at time
    # :active   - URL is live and resolving
    #
    def status
      return :paused   if paused?
      return :expired  if expires_at.present? && expires_at <= ::Time.current
      return :upcoming if starts_at.present? && starts_at > ::Time.current

      :active
    end

    private

    def key_candidate
      (0...key_length).map { RailsUrlShortener.charset[rand(RailsUrlShortener.charset.size)] }.join
    end

    def generate_key
      return if key.present?

      loop do
        # plus to the key length if after 10 attempts was not found a candidate
        self.key_length += 1 if generating_retries >= 10
        self.key = key_candidate
        self.generating_retries += 1
        break unless self.class.exists?(key: key)
      end
    end

    def prevent_key_change
      return unless key_changed?

      errors.add(:key, 'cannot be changed after creation')
      throw(:abort)
    end
  end
end
