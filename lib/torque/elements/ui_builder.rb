# frozen_string_literal: true

require_relative 'ui/defaults'
require_relative 'ui/options_handlers'
require_relative 'ui/rendering'

module Torque
  module Elements
    # = Torque Elements \UI Helpers
    class UiBuilder
      include OptionsHandlers
      include Rendering
      include Defaults

      CONTENT_OPTIONS = (ContentHandler::PARTS - [:content]).map(&:to_s).map(&:freeze).freeze
      SPECIAL_OPTIONS = {
        '@content' => :flatten_content_option,
        '@append' => :flatten_append_option,
        '@controller' => :flatten_controller_option,
      }

      SETTINGS = {
        default_gap: '1.5ex',
        default_col_size: { style: 'width: 10px' },
        default_col_stretch: { style: 'width: stretch' },
        default_table_skeleton_rows: 10,
      }

      attr_reader :view_context

      delegate :attribute_name, to: 'Torque::Elements'
      delegate :presets, to: :class
      delegate_missing_to :view_context

      class << self
        def new(context, framework: nil)
          return super(context) if self != UiBuilder

          raise MissingFrameworkError, <<~MSG.squish unless (klass = framework_classes[normalize_name(framework)])
            No UI framework named '#{framework}'.
            Please make sure it is defined and added to the list of supported frameworks.
          MSG

          klass.new(context)
        end

        def presets
          @presets ||= Hash.new { |hash, key| hash[key] = {} }
        end

        def add_preset(source, name, options)
          presets[source.to_sym][name.to_sym] = options
        end

        def import_presets(source)
          source.each { |name, values| presets[name].merge!(values) }
        end

        def import_presets_from(mod, method_name: :elements_presets)
          mod.try(:compile_elements_helpers!)
          import_presets(mod.elements_presets) if mod.respond_to?(method_name)
        end

        ## Framework management

        def framework_enabled?(name)
          framework_classes.key?(normalize_name(name))
        end

        def enable_framework(name, base: UiBuilder)
          add_framework(name, Elements.ui_framework_helper(name), base: base)
        end

        def add_framework(name, mod, base: UiBuilder)
          raise ::ArgumentError, <<~MSG.squish unless base <= UiBuilder
            #{base} class must be a subclass of UiBuilder.
          MSG

          framework_classes[normalize_name(name)] = Class.new(base).tap do |klass|
            klass.include(mod)
          end
        end

        def name_of(instance = self)
          framework_classes.key(instance)
        end

        alias framework_name name_of

        def inspect
          if eql?(UiBuilder)
            "#<Torque::Elements::UiBuilder (base class) @frameworks=[#{framework_classes.keys.join(', ')}]>"
          else
            "#<Torque::Elements::UiBuilder (base class) @framework=#{framework_name}>"
          end
        end

        # Hook into the include process to import presets
        def include(*modules)
          modules.each do |mod|
            mod.included_modules.each(&method(:import_presets_from))
            import_presets_from(mod)
          end

          super
        end

        protected

          def normalize_name(name)
            name.to_s.underscore.freeze
          end

          def framework_classes
            @@framework_classes ||= {}
          end
      end

      def initialize(view_context)
        @view_context = view_context
      end

      def framework_name
        self.class.name_of(self.class) || 'NONE'
      end

      def settings
        SETTINGS
      end

      def inspect
        "#<Torque::Elements::UiBuilder framework=#{framework_name}>"
      end

      protected

        def tag_builder
          view_context.tag
        end

        def noop(*)
        end
    end
  end
end
