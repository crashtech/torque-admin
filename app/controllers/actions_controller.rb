# frozen_string_literal: true

module Torque
  module Admin
    module ActionsController
      extend ActiveSupport::Concern

      # TODO: This controller will have some default methods for the default actions produced by the resources
      # admin route mapper. A good example is the `search`, as the default behavior is to use the collection to
      # load the options for a select input, supporting pagination and filters as well as responding to JSON and HTML
      # formats
      #
      # Other good example is preparing to perform an action that can be batched or not. So for example, if there is a
      # `publish` action, we can have a generic handler that will execute a block and upon a successful execution,
      # it will properly respond to the request
    end
  end
end
