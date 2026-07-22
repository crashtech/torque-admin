# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      module Template
        module LocalsHelper
          NULL = Object.new.freeze

          def expect_any_locals!(as: :kwargs)
            @required_locals[:kwargs] = as.to_s
          end

          def expect_yield_block!(as: :block)
            @required_locals[:block] = as.to_s
          end

          def require_local!(name, default_as_str = nil, default: NULL)
            name = name.to_s
            default_as_str ||= default.inspect if default != NULL

            redefinition = @required_locals.key?(name) && @required_locals[name] != default_as_str
            raise ArgumentError, "Local #{name} is already required with a different default value" if redefinition

            @required_locals[name] = default_as_str
          end

          def request_locals_names
            (@required_locals.keys - %i[kwargs block]) << @required_locals.slice(:kwargs, :block)
          end

          def required_locals_annotation
            return '<%# locals: () %>' if @required_locals.empty?

            list = @required_locals.dup
            kwargs = list.delete(:kwargs)
            block = list.delete(:block)

            annotation = list.inject(+'') do |acc, (name, value)|
              acc << ', ' if acc.length > 0
              acc << "#{name}: #{value}".chomp(' ')
            end

            annotation << ", **#{kwargs}" if kwargs
            annotation << ", &#{block}" if block
            "<%# locals: (#{annotation}) %>"
          end

        end
      end
    end
  end
end
