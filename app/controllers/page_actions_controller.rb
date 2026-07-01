# frozen_string_literal: true

module Torque
  module Admin
    module PageActionsController
      extend ActiveSupport::Concern

      attr_reader :page_actions

      included do
        provide_template_ivars :@page_actions
        before_action :assign_page_actions
      end

      protected

        def assign_page_actions(infer: true)
          @page_actions = ButtonsElement.new(:page_actions)
          @page_actions.i18n_options = i18n_default_option if respond_to?(:i18n_default_option, true)
          return unless infer

          add_default_page_actions
          add_extended_page_actions
        end

        def add_default_page_actions(based_on: action_name)
          return unless (resource = try(:admin_resource))

          available = action_methods & resource.actions.each_value.reduce(:+)

          if based_on == 'index'
            add_page_action(:new, preset: :primary) if available.include?('new')
          elsif based_on == 'show'
            add_page_action(:edit, preset: :primary) if available.include?('edit')
            add_page_action(:destroy, preset: :danger) if available.include?('destroy')
          end
        end

        def add_extended_page_actions(based_on: action_name)
          return unless (resource = try(:admin_resource)) && based_on == 'show'

          list = resource.actions[:batch] + resource.actions[:member] - %w[destroy preview edit show]
          return if list.empty?

          @page_actions.group(:more) { list.each { |action| add_page_action(action) } }
        end

        def add_page_action(action_name, href = nil, **)
          # TODO: Don't use relative path, just forward the hash for template handling
          @page_actions.item(action_name.to_sym, href || relative_path_for(action_name), **)
        end
    end
  end
end
