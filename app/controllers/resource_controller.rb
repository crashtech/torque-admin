# frozen_string_literal: true

module Torque
  module Admin
    module ResourceController
      extend ActiveSupport::Concern

      included do
        append_template_path(Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource'))
        append_template_path(Rails.root.join('app', 'templates', 'resource'))
        append_template_path(Admin::APP_DIR.join('templates', 'resource'))
      end
    end
  end
end
