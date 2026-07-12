# frozen_string_literal: true

module Torque
  module Admin
    module IndexController
      extend ActiveSupport::Concern

      class_methods do
        def generate_table_action_on(action, **, &)
          if action_methods.include?(action.to_s)
            prepend_before_action(only: action) { define_table_element(**, &) }
          else
            generated_actions_module.define_method(action) { define_table_element(**, &) }
          end
        end

        def index(as: :table, **, &)
          public_send("generate_#{as}_action_on", :index, **, &)
        end
      end

      protected

        def define_table_element(title: nil, **options, &)
          @page_title = title.to_s if title.present?
          state = assign_index_state_collection(options)

          parts = { action: action_name, resource: try(:admin_resource)&.plural_key }

          name = format(options.delete(:name) || "%<action>s_table_%<resource>s", parts)
          @table = @primary_element = TableElement.new(name, state, **options, as: :table, preset: :index, &)
          @table.skeleton(rows: 30) if false # TODO: Use when streaming
          @table.change(:root, class: [:index_table, action_name])
          @table
        end





      # TODO: Probably the most complex of all the controllers that are based on elements, as index can have multiple
      # shapes and have several related elements (e.g. filters, pagination, actions, batch actions, etc.)
      #
      # Ideally we can have 2 different types of out-of-the-box index pages: table and list, with table as the default.
      # Table is straightforward, with columns and rows. Lists have rows as items of the list, and columns as
      # attributes displayed within each item in specific positions
    end
  end
end
