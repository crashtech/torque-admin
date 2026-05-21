# frozen_string_literal: true

module Torque
  module Admin
    module ResourceController
      extend ActiveSupport::Concern

      included do
        append_template_path(Rails.root.join('app', 'templates', admin_application.name.to_s, 'resource'))
        append_template_path(Rails.root.join('app', 'templates', 'resource'))
        append_template_path(Admin::APP_DIR.join('templates', 'resource'))

        stream_actions(:index, :show) if admin_application.config.stream_actions
      end

      include StreamController

      include CollectionController
      include MemberController

      include IndexController
      include ShowController
      include FormController
      include ActionsController
      include WidgetsController

    end
  end
end
