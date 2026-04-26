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

      initializer 'torque-admin.railtie_setup' do
        ::Rails::Railtie::ABSTRACT_RAILTIES << 'Torque::Admin::Engine'

        ActionDispatch::Routing::Mapper.include(Routing)
        Mapper.send(:undef_method, :admin)
      end
    end
  end
end
