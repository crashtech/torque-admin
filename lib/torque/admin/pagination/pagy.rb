# frozen_string_literal: true

module Torque
  module Admin
    class Pagination
      # = Torque Admin \Pagy Pagination
      class Pagy < Pagination
        attr_reader :pagy

        def apply(scope)
          @pagy = build_pagy(scope)
          result = @pagy.records(scope)

          @count = @pagy.count unless cursor?
          @pages = @pagy.last unless cursor?
          @previous = @pagy.previous
          @next = @pagy.next

          result
        end

        protected

          def build_pagy(scope)
            return ::Pagy::Offset::Countless.new(page:, limit: per) if cursor?

            ::Pagy::Offset.new(count: scope.count, page:, limit: per)
          end
      end
    end
  end
end
