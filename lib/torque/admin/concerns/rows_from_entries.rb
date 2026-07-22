# frozen_string_literal: true

module Torque
  module Admin
    module RowsFromEntries
      def import_rows_from_entries(stream)
        if view_context.try(:template_render_context?)
          import_using_template(stream)
        elsif stream
          import_using_streaming
        else
          import_using_enumerable
        end
      end

      protected

        def import_using_template(stream)
          if (path = template_path).present?
            name = settings(:as, :table)
            type = settings(:source_type, :record).to_s.tr('/', '_')
            append_content_for(:content, view_context.append(<<~RUBY.squish))
              render partial: "#{path}", collection: #{name}.collection, build_from: "_row",
                     as: :#{type}, locals: { table: #{name} }
            RUBY
          end
        end

        def import_using_streaming(templating)
          raise __method__.inspect

          # view_context.initialize_async_process do
          #   sleep 2
          #   templating ? import_using_template : import_using_enumerable
          # end
        end

        def import_using_enumerable
          columns = self.columns
          entries.each do |entry|
            node = row(row_id = row_dom_id(entry), entry:, capture: false) do
              columns.map { |column| cell(row_id, column, entry:).render! }
            end

            append_content_for(:content, node.render!)
          end
        end
    end
  end
end
