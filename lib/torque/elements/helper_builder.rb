# frozen_string_literal: true

require_relative 'frame/renderer'

module Torque
  module Elements
    # = Torque Elements \Helper Builder
    module HelperBuilder
      class Constructor
        REQUIRED = Object.new.freeze

        delegate :attribute_name, to: 'Torque::Elements'

        def initialize(name, with_content: false)
          @name = name
          @arguments = []
          @with_content = with_content

          @ui_builder = UiBuilder.allocate

          @presets = {}
          @properties = Set.new([:as])
          @operations = []
        end

        def preset(name, **options)
          @presets[name] = options
          self
        end

        def argument(name, default: REQUIRED)
          start_operation(name.to_s)
          default = default.equal?(REQUIRED) ? '' : " = #{default.inspect}"
          @arguments << "#{name}#{default}"
          self
        end

        def property(name, as: nil)
          raise ArgumentError, "#{name} is already defined" unless @properties.add?(name.to_sym)
          start_operation("_properties[:#{name}]")
          self
        end

        ## Generic effects

        def generic_formats
          raise ArgumentError, +'Can only be used for generics' unless @name == :method_missing

          @operations << "combine_option('#{attribute_name(prop)}', options, format(#{value.to_s.inspect}, #{@arguments.first}))"
          self
        end

        ## Effects

        def assigns(prop)
          @operations << "combine_option('#{attribute_name(prop)}', options, value)"
          self
        end

        def formats(prop, value = nil, using: value.to_s.inspect)
          @operations << "combine_option('#{attribute_name(prop)}', options, format(#{using}, value))"
          self
        end

        def applies(**changes)
          changes = @ui_builder.flatten_options(changes)
          @operations << "combine_options(options, #{changes.inspect})"
          self
        end

        def import_options
          @operations << "combine_options(options, value)"
          self
        end

        def wrap_content(tag)
          @operations << "combine_option('@content', options, before: '<#{tag}>'.html_safe, after: '</#{tag}>'.html_safe)"
          self
        end

        def adds_to_content(part = :content, property: nil)
          part = part.to_sym.inspect
          part = "(_properties.fetch(#{property.to_sym.inspect}, #{part}))" if property && @properties.add?(property.to_sym)
          @operations << "combine_option('@content', options, #{part} => value)"
          self
        end

        def maps(forces = true, **mapping)
          @operations << "value = #{mapping.inspect}.with_indifferent_access[value]#{' || value' unless forces}"
          self
        end

        def maps_using(const_name)
          @operations << "value = #{const_name}[value]"
          self
        end

        def calls(method, arguments = '(value)')
          @operations << "value = #{method}#{arguments}"
          self
        end

        ## Final compiler

        def compile(mod, source)
          raise ArgumentError, +'No default preset defined' unless @presets.key?(:default)

          @operations << @operations.shift # Swap end position

          if @with_content
            @arguments << "content#{+' = nil' unless @with_content == :required}"
            tag_content = +', *(view_context.safe_join(inner.flatten) if inner&.present?)'
          end
          @arguments << '' if @arguments.any? # Fix for empty set of arguments

          presets = "#{mod.name}::PRESETS[:#{@name}]"
          mod.const_get(:PRESETS)[@name] = @presets
          mod.module_eval(<<~RUBY.tap { puts it if @name == :icon }, source.path, source.lineno - 1)
            # frozen_string_literal: true
            def #{@name}(#{@arguments.join(', ')}*_toggles, preset: nil, **kwargs#{', &block' if @with_content})
              _properties = {}.with_indifferent_access
              options = [*#{presets}.values_at(:default, *preset), kwargs.presence].compact.each_with_object({}) do |input, result|
                _properties.merge!(input.extract!(#{@properties.map(&:inspect).join(', ')}))
                combine_options(result, flatten_options(input))
              end

              _toggles.each { |toggle| _properties[toggle] = true }
              #{+%(combine_option('@content', options, (block_given? ? view_context.capture(&block) : content))) if @with_content}
              #{@operations.join("\n")}

              tag_name = _properties.fetch(:as, '#{@with_content ? 'div' : 'span'}')

              options = collapse_options(options)
              left, *inner, right = options.delete('@content')&.values_at(:prepend, :before, :content, :after, :append)
              view_context.safe_join([*left, tag_builder.public_send(tag_name#{tag_content}, **options), *right])
            end
          RUBY
        end

        private

          def start_operation(op)
            @operations << 'end'
            @operations << "if (value = #{op})"
          end
      end

      private_constant :Constructor

      protected

        def load_definitions(path)
          source = caller_locations(1, 1).first.path
          path = File.expand_path(File.join(source, '..', path) + '.rb')
          module_eval(File.read(path))
        end

        def define(name, with_content: true, &block)
          constructor = Constructor.new(name, with_content: with_content)
          block.call(constructor)

          source = caller_locations(1, 1).first
          constructor.compile(self, source)
        end

        def define_generic(&block)
          define(:method_missing, with_content: true, &block)
          define_method(:respond_to_missing?) { |*| true }
        end

      private

        def self.extended(base)
          base.const_set(:PRESETS, {})
        end

    end
  end
end
