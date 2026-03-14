# frozen_string_literal: true

require 'rails/railtie'

require_relative 'railties/extended_mapper'
require_relative 'railties/route_set'
require_relative 'railties/mapper'

module Torque
  module Admin
    # = Torque Admin Railtie
    #
    # Rails integration and configuration
    class Railtie < ::Rails::Railtie
      config.eager_load_namespaces << Torque::Forms
      config.eager_load_namespaces << Torque::Admin
      config.admin = Admin.config

      rake_tasks do
      end

      runner do
      end

      console do
      end

      # Ensure a valid logger
      initializer 'torque-admin.logger' do |app|
        ActiveSupport.on_load(:torque_admin) do
          config.logger ||= begin
            logger = ::Rails.logger
            logger.respond_to?(:tagged) ? logger : ActiveSupport::TaggedLogging.new(logger)
          end
        end
      end
    end
  end
end
