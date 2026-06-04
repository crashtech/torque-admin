# frozen_string_literal: true

module Torque
  module Admin
    module DashboardController
      extend ActiveSupport::Concern

      included do
        append_template_path Rails.root.join('app', 'templates', admin_application.name.to_s, 'dashboard')
        append_template_path Rails.root.join('app', 'templates', 'dashboard')
        append_template_path Admin::APP_DIR.join('templates', 'dashboard')

        stream_actions :index if admin_application.config.stream_actions

        authorize_actions! skip_if_none: true
      end

      include StreamController

      protected

        def dashboard_name
          self.class.name.gsub(/\A(?:#{"#{admin_application.mod.name}::"})?(.*)Controller\z/, '\1')
        end

        alias_method :authorizable_resource, :dashboard_name

    end
  end
end
