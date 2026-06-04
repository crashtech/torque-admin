# frozen_string_literal: true

module Torque
  module Admin
    module CollectionController
      extend ActiveSupport::Concern

      include BatchController

      # Order here is important, as they overload the load_collection method
      include SortController
      include PaginationController
      include ScopeController
      include FilterController

      included do
        helper_method :collection, :collection_state
      end

      protected

        ## External methods

        def collection
          ivar = collection_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          state = load_collection
          instance_variable_set(:"#{ivar}_state", state)
          instance_variable_set(ivar, state.collection)
        end

        alias_method :load_collection, :collection

        def collection_state
          ivar = :"#{collection_ivar_name}_state"
          instance_variable_get(ivar) if instance_variable_defined?(ivar)
        end

        def load_collection(scope = scoped_resource, **settings)
          extras = settings.extract!(:includes, :preload, :eager_load, :joins)
          scope = super(scope, state = CollectionState.new, **settings)
          scope = extras.inject(scope) { |result, (method, value)| result.public_send(method, value) }
          state.ready!(scope)
        end

        def collection_ivar_name
          :"@#{admin_resource.plural}"
        end
    end
  end
end
