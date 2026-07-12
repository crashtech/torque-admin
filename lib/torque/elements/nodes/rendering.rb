# frozen_string_literal: true

module Torque
  module Elements
    class Node
      # = Torque Elements \Rendering Node
      module Rendering
        extend ActiveSupport::Concern

        attr_reader :settings
        attr_writer :content

        class << self
          def attempted_render_handlers
            Thread.current[:torque_elements_attempted_render_handlers] ||= []
          end
        end

        included do
          class_attribute :settings, instance_accessor: false, default: [].freeze
        end

        class_methods do
          def render_handlers
            @render_handlers ||= [].freeze
          end

          def prepend_render_handler(&block)
            @render_handlers = ([block] + render_handlers).freeze
          end

          def append_render_handler(&block)
            @render_handlers = (render_handlers + [block]).freeze
          end

          def render_handler_for(*, **)
            Rendering.attempted_render_handlers.clear
            defined?(@render_handlers) && @render_handlers.reverse_each do |handler|
              result = handler.call(*, **)
              return result if result
            end

            superclass.render_handler_for(*, **) if superclass.respond_to?(:render_handler_for)
          end

          protected

            def settings=(values)
              self.__class_attr_settings = Array.wrap(values).map(&:to_sym).freeze
            end
        end

        def ignore_depth?
          defined?(@ignore_depth) && @ignore_depth
        end

        def ignore_depth!
          @ignore_depth = true
        end

        def extract_render_args
          # Override this method adding a @render_args to store positional arguments for rendering
        end

        def apply_context_changes(as = id)
          return unless defined?(@element) && @element&.name

          Context.apply_changes(@element.name, as, @options)
          Context.deep_extract_properties(settings_keys, @options) do |props, _|
            merge_settings(props) if props.present?
          end
        end

        def content
          return @content if defined?(@content)
          return unless defined?(@children) && @children.any?

          @content = Traverse.new(@children, **settings&.slice(:max_depth, :min_depth)).with_content do |node, content|
            node.content = content
            node.render!
          end

          return @content unless type == :root && defined?(@element)
          @content = @element.finalize_content_body(@content)
        end

        def render!(**)
          raise ArgumentError, "Node '#{id}' has already been rendered" if defined?(@to_s)

          @to_s = nil
          render(**)
        end

        def render(outer: false)
          return content if outer

          body = content
          options = sanitized_options
          args = @render_args if defined?(@render_args)

          handler, *settings = defined?(@element) ? @element.render_handler_for(self) : render_handler
          return handler.call(*args, body, **options) if handler&.respond_to?(:call)
          return send(handler, args, body, options, *settings) if handler

          missing_handler!
        end

        protected

          def sanitized_options!
            apply_context_changes
            extract_render_args
          end

          def render_handler
            self.class.render_handler_for(self)
          end

          def render_with_helper(args, content, options, helper_method)
            helper_method.call(*args, content, **options, :@node => self)
          end

          def merge_settings(values)
            (@settings ||= {}).merge!(settings)
          end

          def extract_settings(options)
            values = options.extract!(*Core::Nodes::POSITION_OPTIONS, *settings_keys)
            @settings = values if values.present?
          end

          def settings_keys
            type == :root && defined?(@element) ? @element.element_settings : self.class.settings
          end

        private

          def missing_handler!
            raise <<~MESSAGE
              No render handler found for node '#{id}' of type '#{type}'
              #{"From '#{@element.name}' element" if defined?(@element)}
              Attempted:
                #{Rendering.attempted_render_handlers.join(",\n  ")}
            MESSAGE
          end
      end
    end
  end
end
