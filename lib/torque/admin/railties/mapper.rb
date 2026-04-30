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
            options: (options = scope[:options] || {}),
          }

          scope.annotate!(c, da, scope_params)
          new set: set, ast: ast, controller: c, default_action: da,
              to: to, formatted: f, via: via, options_constraints: oc,
              anchor: a, scope_params: scope_params,
              internal: i, options: options.merge(o)
        end
      end

      module Scoping
        def unauthenticated(&block)
          annotate(authenticated: false, &block)
        end

        def with_actions(*actions, &block)
          scope(add_actions: actions.map(&:to_sym), &block)
        end

        def section(name, &block)
          scope(path: name, as: name, annotations: { section: name }, &block)
        end

        def without_actions(*actions, &block)
          scope(except: actions.map(&:to_sym), &block)
        end

        def simple(&block)
          with_scope_level(:simple, &block)
        end

        def annotate(annotations, &block)
          scope(annotations: annotations, &block)
        end

        private

          def merge_annotations_scope(parent, child)
            merge_options_scope(parent, child)
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

          def initialize(entity, simple, *, source: nil, **)
            super(entity, false, *, **)
            @simple = simple
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
        end

        delegate :action_scope?, to: :@scope

        Resource = Class.new(ActionDispatch::Routing::Mapper::Resources::Resource)
        Resource.prepend AdminResource

        SingletonResource = Class.new(ActionDispatch::Routing::Mapper::Resources::SingletonResource)
        SingletonResource.prepend AdminResource

        def resource(*resources, concerns: nil, actions: nil, source: nil, widgets: nil, **options, &)
          return self if apply_common_behavior_for(:resource, resources, concerns:, **options, &)

          options = apply_action_options(:resource, options).merge(source: source)
          instance = SingletonResource.new(resources.pop, @scope.simple?, @scope[:shallow], **options)

          with_scope_level(:resource) do
            resource_scope(instance) do
              yield if block_given?
              concerns(*concerns) if concerns
              draw_mappings_for_resource(instance, actions, widgets)
            end
          end
        end

        def resources(*resources, concerns: nil, actions: nil, source: nil, widgets: nil, **options, &)
          return self if apply_common_behavior_for(:resources, resources, concerns:, **options, &)

          options = apply_action_options(:resources, options).merge(source: source)
          instance = Resource.new(resources.pop, @scope.simple?, @scope[:shallow], **options)

          with_scope_level(:resources) do
            resource_scope(instance) do
              yield if block_given?
              concerns(*concerns) if concerns
              draw_mappings_for_resources(instance, actions, widgets)
            end
          end
        end

        def actions(*, **, &block)
          raise ArgumentError, +"can't use actions outside resource(s) scope" unless parent_resource

          block = -> { action(*, **) } unless block_given?
          block = block.then { |b| -> { path_scope(parent_resource.actions_scope, &b) } } unless resource_method_scope?
          block = block.then { |b| -> { shallow_scope(&b) } } if shallow?
          with_scope_level(:action, &block)
        end

        def action(*actions, view: false, add_alias: false, action: nil, via: :patch)
          return actions(*actions, view: view, add_alias: add_alias, action: action, via: via) unless action_scope?

          annotate(type: :action) do
            actions.each do |name|
              view ? get(name, action: action).match(name, via: via) : match(name, action: action, via: via)
              add_alias_for_action(action) if add_alias
            end
          end
        end

        def widgets(*list, action: nil, on: nil)
          raise ArgumentError, +"can't use widgets outside resource(s) scope" unless parent_resource

          on ||= @scope.scope_level == :resources ? :collection : :member if resource_scope?
          annotate(type: :widget) { list.each { |widget| get(widget, action: action, on: on) } }
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

          def draw_mappings_for_resource(resource, actions, widgets) # rubocop:disable Metrics/*
            set = resource.actions.to_set

            widgets(*widgets) if widgets

            new { get(:new) } if set.include?(:new)

            member do
              action(*actions, add_alias: true) if actions
              delete(:destroy) if set.include?(:destroy)

              get(:preview) if set.include?(:preview)
              get(:edit) if set.include?(:edit)
              get(:show) if set.include?(:show)
              patch(:update).put(:update) if set.include?(:update)
            end

            collection { post(:create) } if set.include?(:create)
          end

          def draw_mappings_for_resources(resource, actions, widgets) # rubocop:disable Metrics/*
            set = resource.actions.to_set

            widgets(*widgets) if widgets

            collection do
              get(:search) if set.include?(:search)
              get(:index) if set.include?(:index)
              post(:create) if set.include?(:create)
              patch(:upsert).put(:upsert) if set.include?(:upsert)
            end

            new { get(:new) } if set.include?(:new)

            actions do
              action(*actions, add_alias: true) if actions
              delete(:destroy) if set.include?(:destroy)
            end

            member do
              get(:preview) if set.include?(:preview)
              get(:edit) if set.include?(:edit)
              get(:show) if set.include?(:show)
              patch(:update).put(:update) if set.include?(:update)
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

        def dashboard_root(as: :dashboard)
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
        ADMIN_OPTIONS = %i[annotations add_actions].freeze

        def options
          ADMIN_OPTIONS + super
        end

        def annotate!(controller, action, params)
          return unless (notes = @hash[:annotations])

          resource = annotate_resource(controller, action)

          data = notes.slice(:section, :authenticated)
          data[:resource] = resource if resource
          data[:type] = annotation(:type) || scope_level

          params[:options] = params[:options].merge(annotations: data)
        end

        def simple?
          scope_level == :simple
        end

        def action_scope?
          scope_level == :action
        end

        def annotation(name)
          @hash[:annotations]&.[](name)
        end

        def annotated?(key, value)
          annotation(key) == value
        end

        def action_name(name_prefix, prefix, collection_name, member_name)
          case annotation(:type)
          when :action
            [prefix, name_prefix, collection_name]
          when :widget
            source = parent.scope_level == :member ? member_name : collection_name
            [name_prefix, source, prefix]
          else super
          end
        end

        private

          def annotate_resource(controller, action)
            return unless (instance = @hash[:scope_level_resource])

            name = [*@hash[:module], instance.singular].join('/')
            controller = [*@hash[:module], controller].join('/')

            resource = annotation(:admin_application).fetch_resource(name)
            resource.enhance_from_route(self, action.to_s)
            resource.assign_handler(controller, instance.singleton?)
          end
      end

      def initialize(set)
        super(set)
        @scope = Scope.new(path_names: @set.resources_path_names)
      end

      include Scoping
      include Resources
      include Dashboards
      include Authentication
    end
  end
end
