# frozen_string_literal: true

module Torque
  module Admin
    module PaginationController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, state, paginate: build_pagination_settings, **)
          scope = apply_collection_pagination(scope, state, paginate) if paginate
          defined?(super) ? super(scope, state, **) : scope
        end

        def build_pagination_settings(page: nil, per: nil, per_options: nil, mode: :page)
          { page:, per:, per_options:, mode: }
        end

        def apply_collection_pagination(scope, state, settings)
          return scope unless scope.respond_to?(:offset)

          adapter = admin_application_config.resources.pagination_adapter
          pagination = Pagination.build(adapter, **settings.compact,
            page: settings.fetch(:page, params[:page]),
            per: settings.fetch(:per, params[:per]),
            href: method(:pagination_page_href),
            per_href: method(:pagination_per_href),
          )

          result = pagination.apply(scope)
          state.provide(:paging, pagination)
          result
        end

        def pagination_page_href(page)
          query = request.query_parameters.merge('page' => page)
          [request.path, query.to_query].join('?')
        end

        def pagination_per_href(per)
          query = request.query_parameters.except('page').merge('per' => per)
          [request.path, query.to_query].join('?')
        end
    end
  end
end
