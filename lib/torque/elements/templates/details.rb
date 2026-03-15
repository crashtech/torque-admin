# frozen_string_literal: true

module Torque
  module Elements
    module Templates

      def self.extract_details(options)
        result = {}

        if (prefixes = options[:template_prefixes]).present?
          (result[:template] ||= {})[:prefixes] = Array.wrap(prefixes)
        end

        if (source = options[:build_from]).present?
          (result[:template] ||= {})[:source] = source.to_s
        end

        result
      end

      module AbstractRenderer
        private

          def extract_details(options)
            super.merge(Templates.extract_details(options))
          end
      end

      module LookupContext
        private

          def initialize_details(_target, details)
            super.merge(Templates.extract_details(details))
          end
      end
    end
  end
end
