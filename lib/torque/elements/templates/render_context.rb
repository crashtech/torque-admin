# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Template Render Context
      class RenderContext < ActionView::Base
        include Helpers::Template

        delegate :compiled_method_container, to: :class
        delegate_missing_to :@view_context

        module Reloader
          def clear
            super
            RenderContext.instance_variable_set(:@container, nil)
          end
        end

        class << self
          def compiled_method_container
            @container ||= Module.new.tap { |mod| include mod }
          end
        end

        def initialize(*)
          super
          @_request = nil
        end

        def view_cache_dependencies
          [].freeze
        end

        def template_render_context?
          true
        end

        def process_table_body(element)
          current = element.accessors.define_ivar(:current)
          name = -element.settings(:as, :table).to_s

          source = +''
          source << "<%- #{name}.entries.each do |entry| -%>"
          source << "<%- #{current} = entry -%>"
          source << "<%= #{name}.row(entry) { content_tag(:td, entry.id) } -%>"
          source << '<%- end -%>'

          element.body(source.html_safe).render!
        end

        def inspect
          "#<#{self.class.name}#{'%#016x' % (object_id << 1)}>"
        end
      end
    end
  end
end
