# frozen_string_literal: true

module Torque
  module Admin
    module FormattingHelper
      extend Elements::Formatter::Declarations

      ## Generic formatters

      formatter(:uuid) do |value, as: 'samp', **options|
        content_tag(as, value.to_s[0..7], title: value, **options)
      end

      ## Styled formatters

      formatter(:badge, context: %i[entry attribute]) do |value, with: nil, entry: nil, attribute: nil, **options|
        mapped = with&.[](value.to_s.to_sym) || with&.[](value)
        mapped = { color: mapped } unless mapped.nil? || mapped.is_a?(Hash)
        mapped = mapped.to_h
        label = mapped.fetch(:label) { human_attribute_name_for(value, entry, attribute) }
        ui.badge(label, **options, **mapped.except(:label))
      end

      formatter(:badges, context: %i[entry attribute]) do |values, **options|
        result = safe_join(Array(values).map { |value| formatter.badge(value, **options) })
        ui.respond_to?(:badges) ? ui.badges(result) : result
      end

      ## Records formatter

      formatter(:record) do |record, title: nil|
        title &&= title.is_a?(String) ? title : record.public_send(title)
        title ||= try(:implicit_resource_title_for, record) || record.id
        next title unless admin_routable?(record)

        path = Rails.error.handle(ActionController::UrlGenerationError, severity: :info) { url_for(record) }
        path ? link_to(title, path) : title
      end

      formatter(:count) do |collection|
        pluralize(collection.size, collection.klass.model_name.human)
      end

      def human_attribute_name_for(value, entry = nil, attribute = nil)
        default = value.to_s.humanize
        return default unless attribute && entry.class.respond_to?(:human_attribute_name)

        entry.class.human_attribute_name("#{attribute}.#{value}", default:)
      end

      def admin_routable?(record)
        _routes.polymorphic_mappings.key?(record.to_model.model_name.name)
      end

      def formatter_for(value)
        case value
        when ->(v) { v.respond_to?(:to_model) } then :record
        when ActiveRecord::Relation then :count
        else super
        end
      end
    end
  end
end
