module RailsUrlShortener
  module Shortenable
    extend ActiveSupport::Concern

    class_methods do
      # =========================
      # ONE
      # =========================
      def has_short_url(name = :url, dependent: :nullify)
        kind_value = name.to_s

        has_one(
          name,
          -> { where(kind: kind_value) },
          class_name: 'RailsUrlShortener::Url',
          as: :owner,
          inverse_of: :owner,
          dependent: dependent
        )

        accepts_nested_attributes_for name

        define_method("#{name}_short_url") do
          public_send(name)&.to_short_url
        end

        define_method("#{name}_url") do
          public_send(name)&.url
        end

        define_method("has_#{name}?") do
          public_send(name).present?
        end
      end

      # =========================
      # MANY
      # =========================
      def has_short_urls(name = :urls, dependent: :nullify)
        kind_value = name.to_s.singularize

        has_many(
          name,
          -> { where(kind: kind_value) },
          class_name: 'RailsUrlShortener::Url',
          as: :owner,
          inverse_of: :owner,
          dependent: dependent
        )

        accepts_nested_attributes_for name

        define_method("#{name}_short_urls") do
          public_send(name).map(&:to_short_url)
        end

        define_method("#{name}_urls") do
          public_send(name).map(&:url)
        end

        define_method("has_#{name}?") do
          public_send(name).any?
        end
      end
    end
  end
end
