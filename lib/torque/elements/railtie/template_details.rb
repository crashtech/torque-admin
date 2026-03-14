# frozen_string_literal: true

module Torque
  module Elements
    module TemplateDetails
      module Requested
        extend ActiveSupport::Concern

        attr_reader :template_prefixes

        def initialize(template_prefixes:, **kwargs)
          super(**kwargs)
          @template_prefixes = template_prefixes
        end
      end
    end
  end
end
