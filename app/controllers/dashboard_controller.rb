# frozen_string_literal: true

module Torque
  module Admin
    module DashboardController
      extend ActiveSupport::Concern

      included do
        [
          Rails.root.join('app', 'templates', admin_application.name.to_s, 'dashboard'),
          Rails.root.join('app', 'templates', 'dashboard'),
          Admin::APP_DIR.join('templates', 'dashboard'),
        ].each { |path| append_template_path(path, prefix: admin_application.name.to_s) if path.exist? }

        helper_method :dashboard_name

        # stream_actions :index if admin_application.config.stream_actions

        authorize_actions! skip_if_none: true
      end

      include StreamController

      class_methods do
        def controller_type
          :dashboard
        end
      end

      protected

        def dashboard_name
          self.class.name.gsub(/\A(?:#{"#{admin_application.mod.name}::"})?(.*?)(?:Dashboard)?Controller\z/, '\1')
        end

        def authorizable_resource
          admin_controller_name
        end

        def i18n_default_option
          (super || {}).merge(name: dashboard_name.tr('/', ' ').titleize)
        end

    end
  end
end
