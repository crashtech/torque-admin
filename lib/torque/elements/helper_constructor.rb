# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Helper Constructor
    module HelperConstructor
      attr_reader :presets

      def compile_elements_helpers!
        return if @pending.nil?

        source = +''
        while (instance = @pending.shift&.last)
          source << instance.compile(@presets, @shared) << "\n"
        end

        source.prepend("def self.elements_presets; #{@presets.inspect}; end\n\n") if @presets.any?
        compile_content(source) unless source.empty?
      ensure
        @presets = @pending = @shared = nil
      end

      protected

        def load_definitions(path, from: nil)
          from ||= File.join(caller_locations(1, 1).first.path, '..')
          path = File.expand_path(File.join(from, path) << '.rb')
          module_eval(File.read(path), path, 1)
        end

        def shared(property, &block)
          @shared[property.to_sym] << block
        end

        def define(helper, with_content: true, &block)
          block.call(@pending[helper = helper.to_sym] ||= HelperBuilder.new(helper, with_content: with_content))
        end

        def associate(helper, to:, **)
          @pending[helper = helper.to_sym] ||= AliasBuilder.new(helper, to, **)
        end

      private

        def compile_content(content)
          @file = Tempfile.new(["#{name.demodulize.underscore}_helpers", '.rb'])
          @file.write(source = "# frozen_string_literal: true\n#{content}")
          module_eval(content, @file.path, 1)
        end

        def self.extended(base)
          base.instance_variable_set(:@presets, {})
          base.instance_variable_set(:@pending, {})
          base.instance_variable_set(:@shared, Hash.new { |h, k| h[k] = [] })
        end

    end
  end
end
