# frozen_string_literal: true

module Torque
  module Elements
    module TemplateDetails
      module Requested
        extend ActiveSupport::Concern

        TemplateKeys = Struct.new(:prefixes, :source)

        attr_reader :template_keys

        def initialize(template: nil, **kwargs)
          super(**kwargs)
          @template_keys = TemplateKeys.new(*template.values_at(:prefixes, :source)) if template
        end

        def template_source_path
          return unless (source = template_keys&.source&.presence)

          ActionView::TemplatePath.parse(source)
        end
      end
    end
  end
end
