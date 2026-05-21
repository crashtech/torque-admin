# frozen_string_literal: true

module Torque
  module Admin
    module CollectionController
      extend ActiveSupport::Concern

      included do
        helper_method(:collection)
      end

      protected

        ## External methods

        def collection
          ivar = collection_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, initialize_collection)
        end

        def initialize_collection
          result = load_collection
          result = filter_collection(result)
          calculate_collection_scopes(result)

          result = scope_collection(result)
          result = sort_collection(result)
          result = paginate_collection(result)
          result
        end

        # Internal methods

        def load_collection
        end

        def filter_collection(source)
        end

        def scope_collection(source)
        end

        def sort_collection(source)
        end

        def paginate_collection(source)
        end

        def calculate_collection_scopes(source)
        end

        def collection_ivar_name
          :"@#{route_annotation(:resource).plural}"
        end
    end
  end
end
