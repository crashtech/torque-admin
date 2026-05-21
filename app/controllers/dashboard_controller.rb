# frozen_string_literal: true

module Torque
  module Admin
    module DashboardController
      extend ActiveSupport::Concern

      included do
        append_template_path(Rails.root.join('app', 'templates', admin_application.name.to_s, 'dashboard'))
        append_template_path(Rails.root.join('app', 'templates', 'dashboard'))
        append_template_path(Admin::APP_DIR.join('templates', 'dashboard'))
        stream_actions(:index) if admin_application.config.stream_actions
      end

      include StreamController

    end
  end
end
