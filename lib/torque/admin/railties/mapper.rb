# frozen_string_literal: true

module Torque
  module Admin
    class Mapper < ActionDispatch::Routing::Mapper
      module Scoping
        def unauthenticated(&block)
          scope(authenticated: false, &block)
        end

        def with_actions(*actions, &block)
          scope(add_actions: actions.map(&:to_sym), &block)
        end

        def section(name, &block)
          scope(path: name, as: name, &block)
        end

        def without_actions(*actions, &block)
          scope(except: actions.map(&:to_sym), &block)
        end

        def simple(&block)
          with_scope_level(:simple, &block)
        end

        private

          def merge_authenticated_scope(_, child)
            child
          end

          def merge_add_actions_scope(parent, child)
            parent ? parent + child : child
          end

      end

      module Resources
        module AdminResource
          def self.default_actions(singleton)
            if singleton
              %i[new create show preview edit update destroy]
            else
              %i[index search new create upsert show preview edit update destroy]
            end
          end

          def initialize(entities, simple, *, actions: nil, **)
            super(entities, false, *, **)
            @simple = simple
            @actions = actions
          end

          def default_actions
            AdminResource.default_actions(singleton?)
          end

          def resource_scope
            @simple ? 'simple_resource' : controller
          end

          def actions_scope
            "#{path}(/:#{param})"
          end

          def extra_actions
            @actions
          end
        end

        Resource = Class.new(ActionDispatch::Routing::Mapper::Resources::Resource)
        Resource.prepend AdminResource

        SingletonResource = Class.new(ActionDispatch::Routing::Mapper::Resources::SingletonResource)
        SingletonResource.prepend AdminResource

        def resource(*resources, concerns: nil, **options, &block)
        end

        def resources(*resources, concerns: nil, actions: nil, **options, &)
          return self if apply_common_behavior_for(:resources, resources, concerns:, **options, &)

          options = apply_action_options(:resources, options, actions)
          instance = Resource.new(resources.pop, @scope.simple_resource?, @scope[:shallow], **options)

          with_scope_level(:resources) do
            resource_scope(instance) do
              yield if block_given?
              draw_mappings_for_resources(instance)
            end
          end
        end

        def actions(&block)
          raise ArgumentError, +"can't use actions outside resource(s) scope" unless resource_scope?

          with_scope_level(:actions) do
            if shallow?
              shallow_scope { path_scope(parent_resource.actions_scope, &block) }
            else
              path_scope(parent_resource.actions_scope, &block)
            end
          end
        end

        def action(*actions, view: false, add_alias: false, action: nil)
          unless resource_method_scope?
            return actions { action(*actions, view: view, add_alias: add_alias, action: action) }
          end

          options = { action: action } if action
          actions.each do |action|
            view ? get(action, **options).patch(action) : patch(action, **options)
            add_alias_for_action(action) if add_alias
          end
        end

        def searchable(*resources, **)
          return self if apply_common_behavior_for(:searchable, resources, **)

          with_scope_level(:resources) do
            resource_scope(Resource.new(resources.pop, true, @scope[:shallow])) do
              collection { get(:search) }
            end
          end
        end

        private

          def canonical_action?(action)
            (resource_method_scope? && action == :upsert) || super
          end

          def name_for_action(as, action)
            super if as != ActionDispatch::Routing::Mapper::DEFAULT || %w[destroy upsert].exclude?(action)
          end

          def apply_action_options(method, options, actions)
            result = super(method, options)
            result[:actions] = [*actions, *@scope[:add_actions]]
            result
          end

          def applicable_actions_for(method)
            AdminResource.default_actions(method == :resource)
          end

          def add_alias_for_action(action)
            prefix = prefix_name_for_action(nil, action)
            parts = [prefix, @scope[:as], parent_resource.collection_name].compact

            if (route = @set.named_routes[parts.join('_')])
              parts[-1] = parent_resource.member_name
              @set.named_routes[parts.join('_')] = route
            end
          end

          def draw_mappings_for_resources(resource)
            actions = resource.actions.to_set

            actions do
              action(*resource.extra_actions, add_alias: true) if resource.extra_actions
              delete(:destroy) if actions.include?(:destroy)
            end

            member do
              get(:preview) if actions.include?(:preview)
              get(:edit) if actions.include?(:edit)
              get(:show) if actions.include?(:show)
              patch(:update).put(:update) if actions.include?(:update)
            end

            new { get(:new) } if actions.include?(:new)

            collection do
              get(:search) if actions.include?(:search)
              get(:index) if actions.include?(:index)
              post(:create) if actions.include?(:create)
              patch(:upsert).put(:upsert) if actions.include?(:upsert)
            end
          end
      end

      class Scope < ActionDispatch::Routing::Mapper::Scope
        ADMIN_OPTIONS = %i[authenticated add_actions].freeze

        def options
          super + ADMIN_OPTIONS
        end

        def simple_resource?
          scope_level == :simple
        end

        def resource_method_scope?
          scope_level == :actions || super
        end

        def action_name(name_prefix, prefix, collection_name, _)
          return super unless scope_level == :actions

          [prefix, name_prefix, collection_name]
        end
      end

      def initialize(set, admin_application)
        super(set)
        @scope = Scope.new(path_names: @set.resources_path_names)
        @admin_application = admin_application
      end

      include Scoping
      include Resources
    end
  end
end
