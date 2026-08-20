# frozen_string_literal: true

module Torque
  module Admin
    module CollectionController
      extend ActiveSupport::Concern

      include BatchController

      # Order here is important, as they overload the load_collection method
      include PaginationController
      include SortController
      include ScopesController
      include FilterController

      included do
        helper_method :collection, :collection_state
      end

      class_methods do
        %i[includes preload eager_load joins].each do |method|
          define_method(method) do |*args, only: :index, except: nil, all: false|
            only, cond = nil, :processing_member_action? if all
            proc = ->(state) { state.collection = state.collection.public_send(method, *args) }
            before_action(only:, except:, unless: cond) { collection_state.on_ready(&proc) }
          end
        end
      end

      protected

        ## External methods

        def collection
          ivar = collection_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, load_collection(state: collection_state))
        end

        def collection_state
          ivar = :"#{collection_ivar_name}_state"
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, CollectionState.new)
        end

        def load_collection(scope = scoped_resource, state: nil, **)
          result = super(scope, state, **)
          state&.ready!(result)
          result
        end

        def assign_index_state_collection(options)
          result = load_collection(state: collection_state, **options.extract!(:filter, :paginate, :scopes, :sort))
          instance_variable_set(collection_ivar_name, result)
          collection_state
        end

        def collection_ivar_name
          :"@#{admin_resource.plural_key}"
        end
    end
  end
end
