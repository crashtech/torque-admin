# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Alias Builder
    class AliasBuilder
      def initialize(name, original, **extensions)
        @name = name
        @original = original
        @extensions = extensions
      end

      def compile(*)
        presets = @extensions.delete(:preset)
        presets = presets.present? ? Array.wrap(presets).inspect : '[]'
        extensions = ", **#{@extensions.inspect}" if @extensions.present?

        <<~RUBY
          def #{@name}(*args, **kwargs, &block)
            preset = #{presets}.push(*kwargs.delete(:preset))
            #{@original}(*args, preset: preset#{extensions}, **kwargs, &block)
          end
        RUBY
      end
    end
  end
end
