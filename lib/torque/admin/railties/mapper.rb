# frozen_string_literal: true

module Torque
  module Admin
    class Mapper < ActionDispatch::Routing::Mapper
      module Mapping
        def build(scope, set, ast, c, da, to, via, f, oc, a, i, o) # rubocop:disable all
          return super unless scope.is_a?(Scope)

          scope_params = {
            blocks: scope[:blocks] || [],
            constraints: scope[:constraints] || {},
            defaults: (scope[:defaults] || {}).dup,
            module: scope[:module],
            options: scope[:options] || {},
          }

          options = scope.to_params
          if (resource = fetch_admin_resource(scope, set))
            resource.enhance_from_route(scope, da)
            controller = [*scope[:module], c].join('/')
            options[:resource] = resource.fetch_handler(controller, scope[:scope_level_resource].singleton?)
          end

          new set: set, ast: ast, controller: c, default_action: da,
              to: to, formatted: f, via: via, options_constraints: oc,
              anchor: a, scope_params: scope_params.deep_merge(options: options),
              internal: i, options: scope_params[:options].merge(o)
        end

        def fetch_admin_resource(scope, set)
          return unless (resource = scope[:scope_level_resource])

          name = [*scope[:module], resource.singular].join('/')
          set.admin_application.fetch_resource(name)
        end
      end

      module Scoping
        def unauthenticated(&block)
          scope(authenticated: false, &block)
        end

        def with_actions(*actions, &block)
          scope(add_actions: actions.map(&:to_sym), &block)
        end

        def section(name, &block)
          scope(path: name, as: name, section: name, &block)
        end

        def without_actions(*actions, &block)
          scope(except: actions.map(&:to_sym), &block)
        end

        def simple(&block)
          with_scope_level(:simple, &block)
        end

        private

          def merge_section_scope(parent, child)
            merge_blocks_scope(parent, child)
          end

          def merge_authenticated_scope(_, child)
            child
          end

          def merge_add_actions_scope(parent, child)
            parent ? parent + child : child
          end
      end

      module Resources # rubocop:disable Metrics/ModuleLength
        module AdminResource
          def self.default_actions(singleton)
            if singleton
              %i[new create show preview edit update destroy]
            else
              %i[index search new create upsert show preview edit update destroy]
            end
          end

          def initialize(entity, simple, *, actions: nil, source: nil, **)
            super(entity, false, *, **)
            @simple = simple
            @actions = actions
            @singular = source&.to_s&.underscore
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

        def resource(*resources, concerns: nil, actions: nil, source: nil, widgets: nil, **options, &)
          return self if apply_common_behavior_for(:resource, resources, concerns:, **options, &)

          options = apply_action_options(:resource, options, actions).merge(source: source)
          instance = SingletonResource.new(resources.pop, @scope.simple_resource?, @scope[:shallow], **options)

          with_scope_level(:resource) do
            resource_scope(instance) do
              yield if block_given?
              concerns(*concerns) if concerns
              widgets(*widgets) if widgets
              draw_mappings_for_resource(instance)
            end
          end
        end

        def resources(*resources, concerns: nil, actions: nil, source: nil, widgets: nil, **options, &)
          return self if apply_common_behavior_for(:resources, resources, concerns:, **options, &)

          options = apply_action_options(:resources, options, actions).merge(source: source)
          instance = Resource.new(resources.pop, @scope.simple_resource?, @scope[:shallow], **options)

          with_scope_level(:resources) do
            resource_scope(instance) do
              yield if block_given?
              concerns(*concerns) if concerns
              widgets(*widgets) if widgets
              draw_mappings_for_resources(instance)
            end
          end
        end

        def actions(&block)
          raise ArgumentError, +"can't use actions outside resource(s) scope" unless resource_scope?

          with_scope_level(:action) do
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

        def widgets(*list, action: nil)
          raise ArgumentError, +"can't use widgets outside resource(s) scope" unless @scope[:scope_level_resource]

          if @scope.scope_level == :resources
            return collection { widgets(*list, action: action) }
          elsif @scope.scope_level == :resource
            return member { widgets(*list, action: action) }
          end

          options = { action: action } if action
          with_scope_level(:widget) do
            list.each { |widget| get(widget, **options) }
          end
        end

        def searchable(*resources, source: nil, **)
          return self if apply_common_behavior_for(:searchable, resources, **)

          with_scope_level(:resources) do
            resource_scope(Resource.new(resources.pop, true, @scope[:shallow], source: source)) do
              collection { get(:search) }
            end
          end
        end

        private

          def canonical_action?(action)
            (resource_method_scope? && action == :upsert) || super
          end

          def action_path(name)
            if %i[new edit].include?(name.to_sym) && @scope.resource_method_scope?
              "#{super}(/:partial)"
            else
              super
            end
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

          def draw_mappings_for_resource(resource) # rubocop:disable Metrics/*
            actions = resource.actions.to_set

            new { get(:new) } if actions.include?(:new)

            member do
              action(*resource.extra_actions, add_alias: true) if resource.extra_actions
              delete(:destroy) if actions.include?(:destroy)

              get(:preview) if actions.include?(:preview)
              get(:edit) if actions.include?(:edit)
              get(:show) if actions.include?(:show)
              patch(:update).put(:update) if actions.include?(:update)
            end

            collection { post(:create) } if actions.include?(:create)
          end

          def draw_mappings_for_resources(resource) # rubocop:disable Metrics/*
            actions = resource.actions.to_set

            collection do
              get(:search) if actions.include?(:search)
              get(:index) if actions.include?(:index)
              post(:create) if actions.include?(:create)
              patch(:upsert).put(:upsert) if actions.include?(:upsert)
            end

            new { get(:new) } if actions.include?(:new)

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
          end
      end

      module Dashboards
        def dashboard(path = nil, partials: nil, as: :dashboard, controller: :dashboard, with_alias: true)
          return scope(path: path, as: path) { dashboard(partials: partials) } if path

          with_scope_level(:dashboard) do
            scope(controller: controller) do
              yield if block_given?
              partials&.each { |partial| get(partial) }
              match_root_route(as: as, action: :index)
              add_dashboard_root_alias(as) if with_alias
            end
          end
        end

        def default_root_dashboard(as: :dashboard)
          dashboard(as: as, with_alias: false) unless @set.named_routes.key?(:dashboard)
          add_dashboard_root_alias(as)
        end

        private

          def add_dashboard_root_alias(name = :dashboard)
            other = [@scope[:as], :root].compact.join('_')
            return if @set.named_routes.key?(other)

            name = [@scope[:as], name].compact.join('_')
            @set.named_routes[other] = @set.named_routes[name]
          end
      end

      module Authentication
        PROVIDERS = %i[rails devise]

        def authenticate(resource, with:, **options, &block)
          raise ArgumentError, "unsupported authentication provider: #{with}" unless PROVIDERS.include?(with)

          send("authenticate_with_#{with}", resource, **options, &block)
        end
      end

      class Scope < ActionDispatch::Routing::Mapper::Scope
        ADMIN_OPTIONS = %i[authenticated add_actions section].freeze

        def options
          ADMIN_OPTIONS + super
        end

        def simple_resource?
          scope_level == :simple
        end

        def resource_method_scope?
          scope_level == :action || scope_level == :widget || super
        end

        def action_name(name_prefix, prefix, collection_name, member_name)
          case scope_level
          when :action then [prefix, name_prefix, collection_name]
          when :widget
            [name_prefix, parent.scope_level == :member ? member_name : collection_name, prefix]
          else super
          end
        end

        def to_params
          @hash.slice(:authenticated).merge(type: scope_level, section: @hash[:section]).compact
        end
      end

      def initialize(set, admin_application)
        super(set)
        @scope = Scope.new(path_names: @set.resources_path_names)
        @admin_application = admin_application
      end

      include Scoping
      include Resources
      include Dashboards
      include Authentication
    end
  end
end
