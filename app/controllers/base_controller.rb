# frozen_string_literal: true

module Torque
  module Admin
    module BaseController
      extend ActiveSupport::Concern

      include Torque::Elements::Frame
      include Torque::Elements::Templates

      delegate :admin_application, :admin_config, :ui_framework, to: :class

      included do
        append_view_path(Admin::APP_DIR.join('views'))
      end

      class_methods do
        delegate :config, to: :admin_application, prefix: true

        def ui_framework
          admin_application.ui_builder.framework_name
        end
      end

    end
  end
end
