# frozen_string_literal: true

module Torque
  module Admin
    # Torque Admin \Rails Routing extension for Rails applications.
    module Routing
      def admin(name = :default, path = nil, app: Torque::Admin[name], **options, &)
        routes = app.engine.routes
        scope_options = routes.default_scope.merge(options.extract!(:authenticated))

        mount_admin_engine(app, path, options) unless app.engine.mounted?
        Mapper.new(routes, app).with_default_scope(scope_options, &)
      end

      private

        def mount_admin_engine(app, path, options)
          mount(app.engine, **app.mount_options(path, options))
          app.engine.mounted = true

          app.engine.routes.clear!
          @set.append(&app.engine.routes.method(:finalize!))
        end
    end
  end
end
