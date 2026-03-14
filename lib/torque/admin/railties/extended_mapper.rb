# frozen_string_literal: true

module Torque
  module Admin
    module Rails
      module ExtendedMapper
        extend ActiveSupport::Concern

        def admin(name = :default, app: Torque::Admin[name], **options, &block)
          app.engine.routes.draw(&block) if block_given?
          return if app.mounted?

          app.mount!(**options)
          mount(app.engine, **admin_mount_options(app, **options))
        end

        private

          def admin_mount_options(app, **other)
            other.except(:path).merge(
              to: app.engine,
              as: app.name.to_s,
              at: app.config.root_path,
            )
          end
      end

      ActionDispatch::Routing::Mapper.include(ExtendedMapper)
    end
  end
end
