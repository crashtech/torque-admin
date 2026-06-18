# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Template
      module Template
        extend ActiveSupport::Concern

        Config = Struct.new(:path, :partial, :var_name, :view_paths, :options)

        class Referer < BasicObject
          def initialize(element)
            @element = element
          end

          def render_content_only!
            @element.render_content_only!
          end

          def [](key)
            @element.render_node(@element.fetch(key))
          end

          def method_missing(name, **)
            @element.render_node(@element.fetch(name), **)
          end
        end

        def use_template(path, partial = true, var_name = type, view_paths = nil, **options)
          @template = Config.new(path.to_s, partial, var_name, view_paths, options.compact)
          self
        end

        def render_in(view_context = Context.view_context, &)
          return super unless defined?(@template)

          with_rendering_context(view_context) do
            root.content = render_template_body(&)
            root.render!(outer: render_content_only?)
          ensure
            @interface = nil
          end
        end

        private

          def render_template_body(&block)
            lookup_context = template_lookup_context

            layout, locals, details = prepare_template_option
            template = find_template_to_render(lookup_context, @template.path, locals, details)
            layout = find_template_to_render(lookup_context, layout, locals, details) if layout

            renderer = ::ActionView::PartialRenderer.new(nil, {})
            renderer.send(:render_partial_template, Context.view_context, locals, template, layout, block).body
          end

          def template_lookup_context
            view_paths = @template.view_paths || Context.view_context.lookup_context.view_paths
            details = Context.view_context.controller.details_for_lookup
            context = ::ActionView::LookupContext.new(view_paths, details)
            context.variants = Context.view_context.lookup_context.variants
            context
          end

          def prepare_template_option
            locals = {}
            keys = [:locals, :layout, :with, *::ActionView::LookupContext.registered_details]

            if (details = @template.options.slice(*keys)).present?
              locals.merge!(details.delete(:locals) || {})
              layout = details.delete(:layout)
              settings = details.key?(:with) ? details.delete(:with) : locals
            elsif @template.options.present?
              locals.merge!(@template.options)
            end

            [layout, locals.merge(@template.var_name => prepare_template_interface(settings)), details]
          end

          def prepare_template_interface(locals)
            return SimpleDelegator.new(self) unless @config

            if locals && @config.arity.between(0, 1)
              load_config!(locals)
            else
              load_config!
            end

            Referer.new(self)
          end

          def find_template_to_render(lookup_context, path, locals, details)
            prefixes = Context.view_context.try(:_elements_prefixes)
            lookup_context.find_template(path, prefixes, @template.partial, locals.keys, details || {})
          end

      end
    end
  end
end
