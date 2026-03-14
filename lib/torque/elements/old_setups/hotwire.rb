# frozen_string_literal: true

register_attribute 'data-controller', ListHandler.new(nested_separator: '--')
