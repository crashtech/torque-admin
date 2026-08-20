# frozen_string_literal: true

module Torque
  module Admin
    class Resource
      # = Torque Admin \Resource Active Model
      module ActiveModel
        def singular_key
          active_model? ? resource_class.model_name.singular : super
        end

        def singular_title
          active_model? ? resource_class.model_name.human : super
        end

        def plural_key
          active_model? ? resource_class.model_name.plural : super
        end

        def plural_title
          active_model? ? resource_class.model_name.human(count: 2) : super
        end

        def attribute_name(attribute)
          return super unless active_model?

          @attribute_names ||= Hash.new { |h, k| h[k] = resource_class.human_attribute_name(k, default: '').presence }
          @attribute_names[attribute]
        end

        def parent_reflections
          @parent_reflections ||= Hash.new do |hash, klass|
            hash[klass] = resource_class.reflect_on_all_associations.find do |association|
              association.belongs_to? && !association.polymorphic? && association.klass == klass
            end
          end
        end

        private

          def active_model?
            return @type == :active_model if defined?(@type)

            @type = :active_model if resource_class.respond_to?(:model_name)
          end
      end
    end
  end
end
