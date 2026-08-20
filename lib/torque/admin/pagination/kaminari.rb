# frozen_string_literal: true

module Torque
  module Admin
    class Pagination
      # = Torque Admin \Kaminari Pagination
      class Kaminari < Pagination
        def apply(scope)
          result = scope.page(page).per(per)

          result = result.without_count if cursor?
          @count = result.total_count unless cursor?
          @pages = result.total_pages unless cursor?
          @previous = result.prev_page
          @next = result.next_page

          result
        end
      end
    end
  end
end
