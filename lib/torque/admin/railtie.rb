# frozen_string_literal: true

require 'rails/railtie'

# require_relative 'railties/extended_mapper'
# require_relative 'railties/route_set'
# require_relative 'railties/mapper'

module Torque
  module Admin
    # = Torque Admin Railtie
    #
    # Rails integration and configuration
    class Railtie < ::Rails::Railtie
      config.eager_load_namespaces << Torque::Forms
      config.eager_load_namespaces << Torque::Admin

      rake_tasks do
      end

      runner do
      end

      console do
      end

      initializer 'torque-admin.railtie_setup' do
        ::Rails::Railtie::ABSTRACT_RAILTIES << 'Torque::Admin::Engine'
      end

      initializer 'torque-admin.action_controller_setup' do
        ActiveSupport.on_load(:action_controller) do
          append_view_path Admin::APP_DIR.join('views') if respond_to?(:append_view_path)
        end
      end
    end
  end
end
