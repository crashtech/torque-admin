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
    end
  end
end
