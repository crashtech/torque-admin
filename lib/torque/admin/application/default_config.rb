# frozen_string_literal: true

require 'active_support/ordered_options'

module Torque
  module Admin
    class Application
      DEFAULT_CONFIG = ActiveSupport::InheritableOptions.new(
        # The title of the admin system. Setting to a plain string will render it as text, while setting it to a
        # proc will render the result of the proc as HTML, or setting as a symbol will invoke the helper method.
        # By default, it is set to nil, which will render the title as the application name.
        title: nil,

        # The name of the parent module in which the admin application module will be defined. By default, it is set to
        # +Object+, which means at the top level.
        parent_module: 'Object',

        # Whether the admin application should be defined as an isolated namespace. There are 3 possible options: false
        # will define the admin application in the parent module without isolation, true will define it as a fully Rails
        # isolated namespace and application, and nil will define a hybrid approach where the admin application will
        # have isolated helpers and routes, but not relative model naming. By default, it is set to nil.
        isolate_namespace: nil,

        # The name of the base controller that will serve as the basis of the specific +TAController+ of the admin
        # application. Set it as a plain string to not cause an unnecessary load of the constant. By default, it is set
        # to +ApplicationController+.
        base_controller: 'ApplicationController',

        # The name of the theme to use for the admin application. The default options are: bootstrap, bulma,
        # semantic_ui, and tailwind. By default, it is set to +tailwind+.
        ui_theme: 'tailwind',
      ).freeze
    end
  end
end
