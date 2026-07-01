# frozen_string_literal: true

require 'action_view/template/resolver'

module Torque
  module Elements
    module Templates
      # = Torque Elements \Templates Resolver
      class Resolver < ActionView::FileSystemResolver

        def initialize(path, prefix = nil)
          super(path)
          @prefix = prefix
        end

        private

          def _find_all(name, prefix, partial, details, key, locals)
            requested_details = key || ActionView::TemplateDetails::Requested.new(**details)
            cache = key ? @unbound_templates : Concurrent::Map.new

            path = ActionView::TemplatePath.build(name, prefix, partial)
            cache_key = requested_details.template_source_path || path
            unbound_templates = cache.compute_if_absent(cache_key.virtual) do
              unbound_templates_from_path(cache_key)
            end

            filter_and_sort_by_details(unbound_templates, requested_details).map do |unbound_template|
              unbound_template.bind_path(path, @prefix)
            end
          end

          def build_unbound_template(template)
            parsed = @path_parser.parse(template.from(@path.size + 1))
            details = parsed.details

            UnboundTemplate.new(
              source_for_template(template),
              template,
              details: details,
              virtual_path: parsed.path.virtual,
            )
          end

          def unbound_templates_from_path(path)
            return [] if path.name.include?('.')

            paths = template_glob("**/#{escape_entry(path.name.to_s)}*")
            paths.map { |path| build_unbound_template(path) }
          end

          def filter_and_sort_by_details(templates, requested_details)
            filtered_templates = templates

            if (source = requested_details.template_keys&.source).present?
              filtered_templates = filtered_templates.select { |template| template.virtual_path == source }
            elsif (prefixes = requested_details.template_keys&.prefixes).present?
              filtered_templates = prefixes.flat_map do |prefix|
                prefix = File.join(prefix, '') # Ensure prefix ends with a separator
                filtered_templates.select { |template| template.virtual_path.start_with?(prefix) }
              end
            end

            super(filtered_templates.compact, requested_details)
          end
      end
    end
  end
end
