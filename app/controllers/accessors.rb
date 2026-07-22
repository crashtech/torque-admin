# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Context
    class Accessors
      Cache = Class.new { alias_method :define_method, :define_singleton_method }
      CONTAINERS_CACHE = Hash.new { |h, k| h[k] = Cache.new }

      READ_MODES = {
        nil => '%<base>s.%<accessor>s',
        hash: '%<base>s[:%<accessor>s]',
        json: '%<base>s["%<accessor>s"]',
        dig: '%<base>s.dig(*%<accessor>s)',
      }

      attr_reader :method_name

      delegate :view_context, to: 'Torque::Elements::Context'
      delegate :define_cached_method, to: :@code_generator

      def initialize(base, prefix)
        template = view_context.instance_variable_get(:@rendering_template)
        template ||= view_context.instance_variable_get(:@current_template)
        base = base.present? ? base.to_s.tr('^a-z_', '_') : "_annonymous_#{Elements.current_template_line}"

        @method_name = :"#{template.method_name}__#{prefix}_#{base}"
        @file = Tempfile.new([method_name.to_s, '.rb'])
        @code_generator = ActiveSupport::CodeGenerator.new(methods_owner, @file.path, 1)
      end

      def finalize!
        @code_generator.execute
        @file.close
      end

      def define_ivar(name)
        define("__#{name}=") { |source| source << "attr_writer :__#{name}" }
        define("__#{name}") { |source| source << "attr_reader :__#{name}" }
      end

      def define_reader(base, accessor, read_mode: nil)
        raise ArgumentError, <<~MSG.squish if (template = READ_MODES[read_mode]).blank?
          Invalid read_mode: #{read_mode.inspect}.
          Must be one of: #{READ_MODES.keys.map(&:inspect)}
        MSG

        define(accessor, "#{read_mode || :read}_#{accessor}") do |source|
          source << "def #{accessor}" << format(template, base:, accessor:) << "end"
        end
      end

      def inspect
        "#<#{self.class.name} method_name=#{@method_name.inspect}>"
      end

      private

        def define(as, canonical_name = nil, &block)
          define_cached_method(canonical_name || as, namespace: :torque_elements_accessors, as:) do |source|
            yield(body = [])
            @file.write(body.join("\n"))
            source.concat(body)
          end

          "#{method_name}.#{as}"
        end

        def methods_owner
          @methods_owner ||= begin
            container = view_context.controller.view_context_class.compiled_method_container
            container.module_eval(<<~RUBY, __FILE__, __LINE__ + 1) unless container.method_defined?(@method_name)
              def #{method_name} = ::Torque::Elements::Accessors::CONTAINERS_CACHE[__method__]
            RUBY

            CONTAINERS_CACHE[@method_name]
          end
        end
    end
  end
end
