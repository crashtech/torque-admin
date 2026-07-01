# frozen_string_literal: true

module Torque
  module Elements
    # Error class that wraps all the other error classes
    StandardError = Class.new(::StandardError)

    # Error when trying to access something on the template when it's only available on the actual view
    UnavailableError = Class.new(::NoMethodError)

    # Error when trying use an UI framework that is not yet available
    MissingFrameworkError = Class.new(::NameError)

    # Error when trying access or render an element that is not found/not defined yet
    NotFound = Class.new(KeyError)

    # Error when executing a template with invalid locals
    StrictLocalsError = Class.new(ActionView::StrictLocalsError) do
      def initialize(argument_error, template)
        adjusted_error = StandardError.new(argument_error.message.sub(' for ', ' when rendering '))
        super(adjusted_error, template)
      end
    end
  end
end
