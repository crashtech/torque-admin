# frozen_string_literal: true

module Torque
  module Admin
    # Torque Admin \Rails Routing extension for Rails applications.
    module Routing
      def admin(name = :default, path = nil, app: Torque::Admin[name], authenticated: nil, **, &)
        routes = app.engine.routes
        scope_options = routes.default_scope.deep_dup
        scope_options[:annotations][:authenticated] = authenticated unless authenticated.nil?

        mount_admin_engine(app, path, **) unless app.engine.mounted?
        Mapper.new(routes).with_default_scope(scope_options, &)
      end

      private

        def mount_admin_engine(app, path, **options)
          mount(app.engine, **app.mount_options(path, options))
          app.engine.mounted = true

          routes = app.engine.routes
          routes.clear!
          routes.append { app.finalize_routes! }
          @set.append { routes.finalize! }
        end
    end
  end
end
