# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Precompile Helpers
      module PrecompileHelper

        def precompile(*keys, static: false, &block)
          source = caller.lazy.grep(Regexp.new(@current_template.identifier)).first
          content = find_or_initialize_precompiled(source[/:(\d+):/, 1].to_i, *keys, &block)
          content = ERB.new(content).result(binding) unless static
          content.html_safe
        end

        private

          def find_or_initialize_precompiled(*keys, &block)
            name = precompiled_name(keys.hash).freeze
            container = compiled_method_container

            if container.instance_variable_defined?(name)
              container.instance_variable_get(name)
            elsif (content = capture(&block)).present?
              # TODO: Swap the current protection to template mode
              container.instance_variable_set(name, content)
            else
              raise ArgumentError, +'Block provided did not produce any content'
            end
          end

          def precompiled_name(id)
            name = "@_#{@current_template.send(:identifier_method_name)}"
            name << "__precompiled_#{id}"
            name << "_#{@current_template.__id__}"
            name.tr('-', '_')
          end

      end
    end
  end
end
