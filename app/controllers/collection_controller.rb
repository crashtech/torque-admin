# frozen_string_literal: true

module Torque
  module Admin
    module CollectionController
      extend ActiveSupport::Concern

      # Order here is important, as they overload the load_collection method
      include FilterController
      include ScopeController
      include SortController
      include PaginationController

      included do
        helper_method(:collection)
      end

      protected

        ## External methods

        def collection
          ivar = collection_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, load_collection)
        end

        def load_collection(scope = nil, **)
          super(scope || scoped_resource, **)
        end

        # TODO: Add a way to configure includes/preload/eager_load for the collection

        def collection_ivar_name
          :"@#{RESOURCE.plural}"
        end
    end
  end
end
