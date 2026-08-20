# frozen_string_literal: true

module Torque
  module Admin
    module SortController
      extend ActiveSupport::Concern

      Sorting = Struct.new(:values, :sortable, :href)

      protected

        def load_collection(scope, state, sort: build_sort_settings, **)
          scope = apply_collection_sort(scope, state, sort) if sort
          defined?(super) ? super(scope, state, **) : scope
        end

        def build_sort_settings(value: params[:sort])
          value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
          return [] unless value.respond_to?(:each_pair)

          value.flat_map do |key, direction|
            next [[nil, key, sort_direction(direction)]] unless direction.respond_to?(:each_pair)

            direction.map { |attribute, nested| [key, attribute, sort_direction(nested)] }
          end
        end

        def apply_collection_sort(scope, state, settings)
          return scope unless scope.respond_to?(:order)

          sorting_state = Sorting.new({}, method(:sortable?), method(:sort_attribute_href))
          settings.each do |(reflection, attribute, direction)|
            scope = apply_collection_sort!(scope, attribute, direction, reflection:)
            sorting_state.values[[reflection&.to_s, attribute.to_s]] = direction
          end

          state.provide(:sorting, sorting_state)
          scope
        end

        def apply_collection_sort!(scope, attribute, direction, reflection: nil, joins: true)
          return scope unless sortable?(attribute, reflection:)

          klass = admin_resource_class
          klass = klass.reflect_on_association(reflection.to_sym).klass if reflection
          scope = scope.left_joins(TrueClass === joins ? reflection.to_sym : joins) if reflection && joins
          scope.merge(klass.order(attribute => direction))
        end

        def sortable_attributes(klass)
          klass.attribute_names
        end

        def sortable?(attribute, reflection: nil)
          klass = admin_resource_class
          klass = klass.reflect_on_association(reflection.to_sym)&.klass if reflection
          return false unless klass.present?

          @_sortable_attributes ||= {}
          list = @_sortable_attributes[klass] ||= sortable_attributes(klass).map(&:to_s).to_set
          list.include?(attribute.to_s)
        end

        def sort_attribute_href(attribute, reflection: nil, key: 'sort', query: nil, reset_page: true, state: collection_state)
          query ||= request.query_parameters
          query = query.except('page') if reset_page

          direction = state.fetch(:values, from: :sorting)[[reflection&.to_s, attribute.to_s]]
          direction = { nil => 'asc', 'asc' => 'desc', 'desc' => nil }[direction]

          value = { attribute => direction }.compact
          query[key] = value && reflection ? { reflection => value } : value
          [request.path, query.compact.to_query.presence].compact.join('?')
        end

      private

        def sort_direction(value)
          value.to_s == 'desc' ? 'desc' : 'asc'
        end
    end
  end
end
