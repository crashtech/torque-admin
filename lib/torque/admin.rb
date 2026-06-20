# frozen_string_literal: true

require_relative 'elements'
require_relative 'forms'

require_relative 'admin/version'

module Torque
  # = Torque Admin
  module Admin
    APP_DIR = Pathname.new(__dir__).join('../../app').freeze

    extend ActiveSupport::Autoload

    autoload :Application
    autoload :Engine
    autoload :Resource

    autoload :CollectionState

    autoload_under :concerns do
      autoload :ItemsFromAction
      autoload :ItemsFromRouter
    end

    # = Torque Admin \Themes
    module Themes
      extend ActiveSupport::Autoload

      autoload :SemanticUI
    end

    class << self
      def [](name)
        instances[name.to_sym] ||= Application.new(name)
      end

      def configure(...)
        self[:default].configure(...)
      end

      def instances
        @instances ||= {}
      end

      private

        def app_autoload(const_name, *subs)
          folder = ActiveSupport::Inflector.pluralize(const_name.to_s.match(/[A-Z][a-z]+\z/).to_s.downcase)
          autoload(const_name, APP_DIR.join(folder, *subs, ActiveSupport::Inflector.underscore(const_name)))
        end
    end

    eager_autoload do
      app_autoload :BaseController
      app_autoload :SettingsController
      app_autoload :StreamController

      app_autoload :ResourceController
      app_autoload :DashboardController
      app_autoload :SimpleController

      app_autoload :CollectionController
      app_autoload :MemberController

      app_autoload :CancancanController, 'authorization'
      app_autoload :PunditController, 'authorization'
      app_autoload :AuthorizationController, 'authorization'

      app_autoload :FilterController, 'collection'
      app_autoload :ScopeController, 'collection'
      app_autoload :SortController, 'collection'
      app_autoload :PaginationController, 'collection'

      app_autoload :IndexController
      app_autoload :ShowController
      app_autoload :FormController
      app_autoload :BatchController
      app_autoload :ActionsController
      app_autoload :WidgetsController

      app_autoload :BaseElement
      app_autoload :MenuElement
      app_autoload :BreadcrumbElement

      app_autoload :ApplicationHelper
    end
  end
end

require 'torque/admin/errors'
require 'torque/admin/railtie'

ActiveSupport.run_load_hooks(:torque_admin, Torque::Admin)
