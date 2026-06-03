# frozen_string_literal: true

require 'active_support/ordered_options'

module Torque
  module Admin
    class Application
      config = ActiveSupport::InheritableOptions
      DEFAULT_CONFIG = config.new(
        # The title of the admin system. Setting to a plain string will render it as text, while setting it to a
        # proc will render the result of the proc as HTML, or setting as a symbol will invoke the helper method.
        # By default, it is set to nil, which will render the title as the application name.
        title: nil,

        # The path to the admin application. By default, it is set to nil, which will require that information at the
        # moment of mounting the application in the main application routes. Setting it to a plain string will set the
        # root path of the admin application.
        root_path: nil,

        # The name of the parent module in which the admin application module will be defined. By default, it is set to
        # +Object+, which means at the top level.
        parent_module: 'Object',

        # Whether the admin application stream heavy actions (like index) by default. By default, it is set to +true+.
        stream_actions: true,

        # The method to use for parallel processing of heavy actions. The default options are: concurrent_ruby,
        # async, or false to disable parallel processing. By default, it is set to +concurrent_ruby+.
        parallel_processing_with: :concurrent_ruby,

        # Whether the admin application should be defined as an isolated namespace. There are 3 possible options: false
        # will define the admin application in the parent module without isolation, true will define it as a fully Rails
        # isolated namespace and application, and nil will define a hybrid approach where the admin application will
        # have isolated helpers and routes, but not relative model naming. By default, it is set to nil.
        isolate_namespace: nil,

        # The name of the base controller that will serve as the basis of the specific +TAController+ of the admin
        # application. Set it as a plain string to not cause an unnecessary load of the constant. By default, it is set
        # to +ApplicationController+.
        base_controller: 'ApplicationController',

        # Indicates whether the admin application should require an authentication by default. By default, it is set
        # to +true+.
        default_authenticated: true,

        # The name of the theme to use for the admin application. The default options are: bootstrap, bulma,
        # semantic_ui, and tailwind. By default, it is set to +tailwind+.
        theme: 'tailwind',

        # The extensions to load for the admin theme. You can provide procs to ran under the context of the ui theme
        # class, or modules to be included in the class.
        theme_extensions: [],

        # The modules to search for elements (lookup will happen in reverse order, so the last module will be searched
        # first). By default, it is set to +Object+ and +Torque::Admin+.
        elements_lookup_context: ['Object', 'Torque::Admin'],

        ## Behaviors Section

        # All specific configuration for handling resources in the admin application.
        resources: config.new(
          # Indicates whether the admin application should use strict loading for resources by default. By default, it
          # is set to +false+, as a common situation
          default_strict_loading: false,
        ),
      ).freeze
    end
  end
end
