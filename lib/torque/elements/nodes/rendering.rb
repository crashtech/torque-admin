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

        def apply_context_changes
          Context.apply_changes(@element.name, id, @options) if defined?(@element) && @element&.name
        end

        def content
          return @content if defined?(@content)
          return unless defined?(@children) && @children.any?

          @content = Traverse.new(@children, **settings&.slice(:max_depth, :min_depth)).with_content do |node, content|
            node.content = content
            node.render!
          end
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
          raise <<~MESSAGE unless handler
            No render handler found for node '#{id}' of type '#{type}'
            #{"From '#{@element.name}' element" if defined?(@element)}
            Attempted:
              #{Rendering.attempted_render_handlers.join(",\n  ")}
          MESSAGE

          return handler.call(*args, content, **options) unless handler.is_a?(Symbol)

          send(handler, args, body, options, *settings)
        end

        protected

          def sanitized_options!
            extract_render_args
            apply_context_changes
          end

          def render_handler
            self.class.render_handler_for(self)
          end

          def render_with_helper(args, content, options, helper_method)
            helper_method.call(*args, content, **options, :@node => self)
          end

          def extract_settings(options)
            keys = @type == :root ? @element&.element_settings : self.class.settings
            values = options.extract!(*Core::Nodes::POSITION_OPTIONS, *keys)
            @settings = values if values.present?
          end
      end
    end
  end
end
