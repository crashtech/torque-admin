# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Helper Constructor
    module HelperConstructor
      attr_reader :presets

      def compile_pending!
        source = +"# frozen_string_literal: true\n"
        while instance = (@pending.shift)&.last
          source << instance.compile(@presets, @shared)
        end

        module_eval(source) unless source.empty?
      end

      def clear!
        @shared = @pending = nil
      end

      protected

        def load_definitions(path)
          source = caller_locations(1, 1).first.path
          path = File.expand_path(File.join(source, '..', path) + '.rb')
          module_eval(File.read(path))
        end

        def shared(property, &block)
          @shared[property.to_sym] << block
        end

        def define(name, with_content: true, compile: Elements.auto_compile_on_define, &block)
          instance = @pending[name = name.to_sym] ||= begin
            HelperBuilder.new(name, with_content: with_content)
          end

          block.call(instance)
          return unless compile

          @pending.delete(name)
          module_eval("# frozen_string_literal: true\n#{instance.compile(@presets, @shared)}")
        end

        def associate(name, to:, compile: Elements.auto_compile_on_define, **extensions)
          instance = @pending[name = name.to_sym] ||= AliasBuilder.new(name, to, **extensions)
          return unless compile

          @pending.delete(name)
          module_eval("# frozen_string_literal: true\n#{instance.compile}")
        end

      private

        def self.extended(base)
          base.instance_variable_set(:@presets, {})
          base.instance_variable_set(:@pending, {})
          base.instance_variable_set(:@shared, Hash.new { |h, k| h[k] = [] })
          base.delegate(:presets, to: base.name)
        end

    end
  end
end
