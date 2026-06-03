# frozen_string_literal: true

module Torque
  module Admin
    module ShowController
      extend ActiveSupport::Concern

      # TODO: Here we can setup a show view paga. Ideally the page can be of 3 types, simple, tabs or grid
      # They all should support an optional sidebar with a definition table about the unerlying record
      # simple: The main part can be devided in sections where sections can be collapsable.
      #   Sections can be a definition table or a reference table (itself/has one or has many)
      # tabs: Tabs is an extention of the above, where each tab is a superset of several simples
      # grid: This is a bit more comples, but the idea is just a simple way to gridify sections
    end
  end
end
