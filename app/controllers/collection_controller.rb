# frozen_string_literal: true

module Torque
  module Admin
    module CollectionController
      extend ActiveSupport::Concern

      include BatchController

      # Order here is important, as they overload the load_collection method
      include FilterController
      include ScopeController
      include SortController
      include PaginationController

      included do
        helper_method :collection
      end

      protected

        ## External methods

        def collection
          ivar = collection_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, load_collection)
        end

        def load_collection(scope = nil, **settings)
          extras = settings.extract!(:includes, :preload, :eager_load, :joins)
          scope = super(scope || scoped_resource, **settings)
          scope = scope.strict_loading if admin_application_config.resource.default_strict_loading
          extras.inject(scope) { |result, (method, value)| result.public_send(method, value) }
        end

        def collection_ivar_name
          :"@#{RESOURCE.plural}"
        end
    end
  end
end
