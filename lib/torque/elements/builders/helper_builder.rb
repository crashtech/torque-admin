# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Helper Builder
    class HelperBuilder
      REQUIRED = Object.new.freeze

      attr_reader :name
      delegate :attribute_name, to: 'Torque::Elements'

      def initialize(name, with_content: false)
        @name = name
        @arguments = []
        @with_content = with_content

        @ui_builder = UiBuilder.allocate

        @current = nil
        @presets = {}
        @operations = {}
        @properties = Set.new([:as])
        @shared_properties = {}
      end

      def preset(name, **options)
        @presets[name] = options
        self
      end

      def toggles(*list, assigns: :class, format: '%s')
        list.each { |toggle| property(toggle).applies(assigns => format(format, toggle)) }
      end

      def imports(*properties, **properties_with_aliases)
        properties.index_by(&:itself).merge(properties_with_aliases).each do |name, shared_prop|
          @shared_properties[name.to_sym] = shared_prop.to_sym
          @properties << name.to_sym
        end
      end

      def argument(name, default: REQUIRED)
        default = default.equal?(REQUIRED) ? '' : " = #{default.inspect}"
        @arguments << "#{name}#{default}"

        swap_current(name.to_sym)
        start_operation(name)

        self
      end

      def property(name)
        swap_current(name = name.to_sym)
        start_operation(name, as_property: true) if @properties.add?(name)
        self
      end

      ## Effects

      def assigns(prop)
        @current << "combine_option('#{attribute_name(prop)}', options, value)"
        self
      end

      def formats(prop, value = nil, using: value.to_s.inspect)
        @current << "combine_option('#{attribute_name(prop)}', options, format(#{using}, value))"
        self
      end

      def applies(**changes)
        changes = @ui_builder.flatten_options(changes)
        @current << "combine_options(options, #{changes.inspect})"
        self
      end

      def import_options
        @current << "combine_options(options, value)"
        self
      end

      def wrap_content(tag)
        @current << "combine_option('@content', options, before: '<#{tag}>'.html_safe, after: '</#{tag}>'.html_safe)"
        self
      end

      def adds_to_content(part = :content, property: nil)
        part = part.to_sym.inspect
        part = "(_properties.fetch(#{property.to_sym.inspect}, #{part}))" if property && @properties.add?(property.to_sym)
        @current << "combine_option('@content', options, #{part} => value)"
        self
      end

      def maps(forces = true, **mapping)
        @current << "value = #{mapping.inspect}.with_indifferent_access[value]#{' || value' unless forces}"
        self
      end

      def maps_using(const_name)
        @current << "value = #{const_name}[value]"
        self
      end

      def calls(method, arguments = '(value)')
        @current << "value = #{method}#{arguments}"
        self
      end

      ## Final compiler

      def compile(presets, shared)
        raise ArgumentError, +'No default preset defined' unless @presets.key?(:default)

        @arguments << "content#{+' = nil' unless @with_content == :required}" if @with_content
        @arguments << '' if @arguments.any?

        import_shared_properties(shared)
        presets[@name] = @presets.dup

        operations = @operations.values.flatten
        operations << operations.shift # Swap end

        <<~RUBY
          def #{@name}(#{@arguments.join(', ')}*_toggles, preset: nil, **kwargs#{', &block' if @with_content})
            _options, _properties = split_options_properties(:#{@name}, [#{@properties.map(&:inspect).join(', ')}], preset, kwargs)
            options = {}

            _toggles.each { |toggle| _properties[toggle] = true }
            #{content_assigner if @with_content}
            #{operations.join("\n")}

            tag_name = _properties.fetch(:as, '#{@with_content ? 'div' : 'span'}')
            render_tag(tag_name, combine_options(_options, options), with_content: #{@with_content.present?.inspect})
          end
        RUBY
      end

      def content_assigner
        +%(combine_option('@content', options, (block_given? ? view_context.capture(&block) : content)))
      end

      private

        def swap_current(scope)
          @current = @operations[scope] ||= []
        end

        def start_operation(op, as_property: false)
          op = "_properties[:#{op}]" if as_property
          @current << 'end'
          @current << "if (value = #{op})"
        end

        def import_shared_properties(shared)
          @shared_properties.each do |prop, as|
            @current = []
            shared.fetch(as).each { |block| block.call(self) }

            if @operations.key?(prop)
              @operations[prop].insert(2, *@current)
            else
              operations, @current = @current, []
              start_operation(prop, as_property: true)
              @operations[prop] = @current + operations
            end
          end
        end
    end
  end
end
