# frozen_string_literal: true

module Torque
  module Admin
    module BatchController
      extend ActiveSupport::Concern

      # TODO: This is the controller in between the index page (or the page that holds the batch form and checkboxes)
      # and the action that will process the batch action. Its purpose is to centralize everything that both sides might
      # need to accomplish their needs. It's out of its scope to do something with a batch action that can also be
      # trigerred from the show page
    end
  end
end
