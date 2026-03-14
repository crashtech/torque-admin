# frozen_string_literal: true

require 'action_view/template/resolver'

module Torque
  module Elements
    module Templates
      # = Torque Elements \Templates Resolver
      class Resolver < ActionView::FileSystemResolver

        private

          def _find_all(name, prefix, partial, details, key, locals)
            requested_details = key || ActionView::TemplateDetails::Requested.new(**details)
            cache = key ? @unbound_templates : Concurrent::Map.new

            unbound_templates =
              cache.compute_if_absent(ActionView::TemplatePath.virtual(name, prefix, partial)) do
                path = ActionView::TemplatePath.build(name, prefix, partial)
                unbound_templates_from_path(path)
              end

            filter_and_sort_by_details(unbound_templates, requested_details).map do |unbound_template|
              unbound_template.bind_prefix(prefix)
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

          def filter_and_sort_by_details(templates, requested_details)
            filtered_templates = templates

            if requested_details.template_prefixes.any?
              filtered_templates = requested_details.template_prefixes.flat_map do |prefix|
                prefix = File.join(prefix, '') # Ensure prefix ends with a separator
                templates.select { |template| template.virtual_path.start_with?(prefix) }
              end
            end

            super(filtered_templates.compact, requested_details)
          end

          def template_glob(glob)
            super(glob.sub(%r{.*/}, '**/'))
          end
      end
    end
  end
end
