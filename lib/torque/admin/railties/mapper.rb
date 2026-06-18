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

          # TODO: We might be creating more routes than necessary, maybe that is why the reload is slow
          scope.annotate!(c, da, scope_params)
          new set: set, ast: ast, controller: c, default_action: da,
              to: to, formatted: f, via: via, options_constraints: oc,
              anchor: a, scope_params: scope_params,
              internal: i, options: options.merge(o)
        end
      end

      module Scoping
        def section(name, **, &)
          scope(path: name, as: name, annotations: { section: name }, **, &)
        end

        def with_actions(*actions, &)
          scope(additional_actions: actions.map(&:to_sym), &)
        end

        def without_actions(*actions, &)
          scope(except: actions.map(&:to_sym), &)
        end

        def simple(&)
          with_scope_level(:simple, &)
        end

        def annotate(annotations, &)
          scope(annotations: annotations, &)
        end

        def external(&)
          mapper = ActionDispatch::Routing::Mapper.new(@set)
          frame = @scope.frame.except(:annotations, :blocks, :options)
          mapper.with_default_scope(frame, &)
        end

        private

          def merge_annotations_scope(parent, child)
            merge_options_scope(parent, child)
          end

          def merge_nested_resources_scope(parent, child)
            merge_options_scope(parent, child) unless child.nil?
          end

          def merge_additional_actions_scope(parent, child)
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

          def simple?
            @simple
          end

          def default_actions
            AdminResource.default_actions(singleton?)
          end

          def resource_scope
            simple? ? 'simple_resource' : controller
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
          return actions(*actions, view:, add_alias:, action:, via:) unless action_scope?

          annotate(type: :action) do
            actions.each do |name|
              view ? get(name, action:).match(name, via:) : match(name, action:, via:)
              add_alias_for_action(action) if add_alias
            end
          end
        end

        def widgets(*list, action: nil, on: nil)
          raise ArgumentError, +"can't use widgets outside resource(s) scope" unless parent_resource

          on ||= @scope.scope_level == :resources ? :collection : :member if resource_scope?
          annotate(type: :widget) { list.each { |widget| get(widget, action:, on:) } }
        end

        def searchable(*resources, source: nil, **)
          return self if apply_common_behavior_for(:searchable, resources, **)

          with_scope_level(:resources) do
            resource_scope(Resource.new(resources.pop, true, @scope[:shallow], source:)) do
              collection { get(:search) }
            end
          end
        end

        private

          def canonical_action?(action)
            (resource_method_scope? && action == :upsert) || super
          end

          def shallow_scope(*)
            scope(nested_resources: nil) { super }
          end

          def resource_scope(*)
            return super if (parent = parent_resource).nil?

            controller = -[*@scope[:module], parent.controller].join('/')
            scope(nested_resources: { parent.nested_param => controller }) { super }
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

            new { annotate(type: :action) { get(:new) } } if set.include?(:new)

            member do
              action(*actions, add_alias: true) if actions

              annotate(type: :action) do
                delete(:destroy) if set.include?(:destroy)

                get(:preview) if set.include?(:preview)
                get(:edit) if set.include?(:edit)
                get(:show) if set.include?(:show)
              end

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

            new { annotate(type: :action) { get(:new) } } if set.include?(:new)

            actions do
              action(*actions, add_alias: true) if actions
              delete(:destroy) if set.include?(:destroy)
            end

            member do
              annotate(type: :action) do
                get(:preview) if set.include?(:preview)
                get(:edit) if set.include?(:edit)
                get(:show) if set.include?(:show)
              end
              patch(:update).put(:update) if set.include?(:update)
            end
          end
      end

      module Dashboards
        def dashboard(path = nil, partials: nil, as: :dashboard, controller: nil, with_alias: true)
          controller ||= [*@scope.annotation(:section), *path, :dashboard].join('_').to_sym

          return scope(path: path, as: path) { dashboard(partials:, as:, controller:, with_alias:) } if path

          with_scope_level(:dashboard) do
            scope(controller: controller) do
              yield if block_given?
              partials&.each { |partial| get(partial) }
              match_root_route(as:, action: :index)
              add_dashboard_root_alias(as) if with_alias
            end
          end
        end

        def dashboard_root(as: :dashboard)
          dashboard(as:, with_alias: false) unless @set.named_routes.key?(:dashboard)
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
        PROVIDERS = %i[rails custom devise]

        def unauthenticated(&)
          annotate(authenticated: false, &)
        end

        def authenticate(resource, with:, **, &block)
          raise ArgumentError, "unsupported authentication provider: #{with}" unless PROVIDERS.include?(with)
          raise ArgumentError, "#{with} authentication requires a block" if %i[rails custom].include?(with) && block.nil?

          admin = @scope.annotation(:admin_application)
          admin.authenticable_resource!(resource, with)

          annotate(resource: admin.fetch_resource(resource), authenticated: false) do
            return external(&block) if block_given?

            send("authenticate_with_#{with}", resource, admin, **)
          end
        end

        private

          def authenticate_with_devise(resource, admin, **)
            external { devise_for(resource, module: "#{admin.mod.name.underscore}/devise", **) }
          end
      end

      class Scope < ActionDispatch::Routing::Mapper::Scope
        ADMIN_OPTIONS = %i[annotations nested_resources additional_actions].freeze

        def options
          ADMIN_OPTIONS + super
        end

        def annotate!(controller, action, params)
          return unless (notes = @hash[:annotations])

          data = notes.slice(:section, :authenticated)
          if (instance = @hash[:scope_level_resource])
            data[:resource] = annotate_resource(instance, controller, action)
            data[:nesting] = @hash[:nested_resources]
            data[:source] = instance.singleton? ? :resource : :resources
          elsif scope_level == :dashboard
            data[:source] = :dashboard
          end

          data[:type] = annotation(:type) || scope_level
          params[:options] = params[:options].merge(annotations: data.compact)
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
            return super if parent.scope_level == :new
            [prefix, name_prefix, collection_name]
          when :widget
            source = parent.scope_level == :member ? member_name : collection_name
            [name_prefix, source, prefix]
          else super
          end
        end

        private

          def annotate_resource(instance, controller, action)
            app = annotation(:admin_application)
            name = -[*@hash[:module], instance.singular].join('/')

            resource = app.fetch_resource(name)
            resource.enhance_from_route(self, action.to_s)
            return resource if instance.simple?

            controller = [*@hash[:module], "#{controller}_controller"].join('/').classify
            app.setup_controller(controller, resource, instance.param)

            nil
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
