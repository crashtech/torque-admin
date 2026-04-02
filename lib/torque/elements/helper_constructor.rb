# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Helper Constructor
    module HelperConstructor
      attr_reader :presets

      def compile_pending!
        source = +''
        while (instance = @pending.shift&.last)
          source << instance.compile(@presets, @shared)
        end

        # TODO: Maybe use a temp file/dir for development to get better backtraces?
        module_eval(source, "virtual: #{name.demodulize.underscore}/helpers.rb") unless source.empty?
      end

      def clear!
        @shared = @pending = nil
      end

      protected

        def load_definitions(path)
          source = caller_locations(1, 1).first.path
          path = File.expand_path(File.join(source, '..', path) << '.rb')
          module_eval(File.read(path), path, 1)
        end

        def shared(property, &block)
          @shared[property.to_sym] << block
        end

        def define(name, with_content: true, compile: Elements.auto_compile_on_define, &block)
          instance = @pending[name = name.to_sym] ||= HelperBuilder.new(name, with_content: with_content)

          block.call(instance)
          return unless compile

          @pending.delete(name)
          compile_content(instance.compile(@presets, @shared))
        end

        def associate(name, to:, compile: Elements.auto_compile_on_define, **extensions)
          instance = @pending[name = name.to_sym] ||= AliasBuilder.new(name, to, **extensions)
          return unless compile

          @pending.delete(name)
          compile_content(instance.compile)
        end

      private

        def compile_content(content, path = nil)
          args = [path, 1] if path
          module_eval("# frozen_string_literal: true\n#{content}", *args)
        end

        def self.extended(base)
          base.instance_variable_set(:@presets, {})
          base.instance_variable_set(:@pending, {})
          base.instance_variable_set(:@shared, Hash.new { |h, k| h[k] = [] })
        end

    end
  end
end
