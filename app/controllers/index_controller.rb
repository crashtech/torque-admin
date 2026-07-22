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

          resource = try(:admin_resource)
          parts = { action: action_name, resource: resource&.plural_key }
          name = format(options.delete(:name) || "%<action>s_table_%<resource>s", parts)

          options[:id] ||= Elements.node_id(name)
          options[:primary_key] ||= self.class.try(:identified_by) || :id
          options[:source_type] ||= resource&.singular_key || admin_controller_name.singularize

          table = @primary_element = assign_table_element(name, state, **options, preset: :index, &)
          table.change(:root, class: [:index_table, action_name])
          table

          # @table.skeleton(rows: 30) if false # TODO: Use when streaming
        end

        def assign_table_element(*, **, &)
          @table = TableElement.new(*, **, &)
        end



    end
  end
end
