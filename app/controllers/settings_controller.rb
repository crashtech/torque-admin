# frozen_string_literal: true

module Torque
  module Admin
    module SettingsController
      extend ActiveSupport::Concern

      # TODO: I'm still not fully convinced that I will need this

      included do
        class_attribute :settings_for_actions, instance_accessor: false, instance_predicate: false, default: {}.freeze
        private_class_method :settings_for_actions, :settings_for_actions=

        helper_method :action_settings
      end

      class_methods do
        def action_settings(*actions, **settings)
          changes = actions.flatten.map(&:to_s).product([settings.deep_symbolize_keys]).to_h
          self.settings_for_actions = settings_for_actions.deep_merge(changes)
          self.settings_for_actions.deep_freeze
        end
      end

      protected

        def action_settings(setting, *, action: action_name)
          self.class.settings_for_actions.dig(action.to_s, setting, *)
        end
    end
  end
end
