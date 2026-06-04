# frozen_string_literal: true

module Torque
  module Admin
    module IndexController
      extend ActiveSupport::Concern

      included do
        alias_element :search_form, :index_form
      end

      # TODO: Probably the most complex of all the controllers that are based on elements, as index can have multiple
      # shapes and have several related elements (e.g. filters, pagination, actions, batch actions, etc.)
      #
      # Ideally we can have 2 different types of out-of-the-box index pages: table and list, with table as the default.
      # Table is straightforward, with columns and rows. Lists have rows as items of the list, and columns as
      # attributes displayed within each item in specific positions
    end
  end
end
