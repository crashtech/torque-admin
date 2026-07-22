# frozen_string_literal: true

require 'rails/railtie'

require_relative 'railties/routing'
require_relative 'railties/mapper'

module Torque
  module Admin
    # = Torque Admin Railtie
    #
    # Rails integration and configuration
    class Railtie < ::Rails::Railtie
      config.eager_load_namespaces << Torque::Forms
      config.eager_load_namespaces << Torque::Admin

      # TODO: Think about this. We need the routes because it's from where we load the resources, but it might not be
      # nice to force the routes the be loaded this way
      console { Rails.application.reload_routes! }

      initializer 'torque-admin.railtie_setup' do
        ::Rails::Railtie::ABSTRACT_RAILTIES << 'Torque::Admin::Engine'

        ActionDispatch::Routing::Mapper.include(Routing)
        ActionDispatch::Routing::Mapper::Mapping.singleton_class.prepend(Mapper::Mapping)
        Mapper.send(:undef_method, :admin)

        config.i18n.load_path << Pathname.new(__dir__).join('en.yml').to_s
      end

      initializer 'torque-admin.action_controller_setup' do
        ActiveSupport.on_load(:action_controller) do
          ActionController::Base::PROTECTED_IVARS.concat(%i[
            @_initialized_side_controllers @_slave_of @_route_annotations
            @_chained_scoped_resource @_chained_members
            @_i18n_default_scopes @_implicit_resource_title
          ])
        end
      end
    end
  end
end
