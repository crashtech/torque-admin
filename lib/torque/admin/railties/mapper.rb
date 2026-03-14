# frozen_string_literal: true

module Torque
  module Admin
    module Rails
      class Mapper < ActionDispatch::Routing::Mapper
        def initialize(set)
          @set = set
          @draw_paths = set.draw_paths
          @scope = Scope.new(path_names: @set.resources_path_names)
          @concerns = {}
        end

        # def resources(*)
        #   raise @scope.inspect
        # end

        def admin(*)
          raise ::NoMethodError, 'unable to define an admin inside another admin block'
        end
      end

      class Scope < ActionDispatch::Routing::Mapper::Scope
        OPTIONS = %i[]

        def options
          super + OPTIONS
        end
      end
    end
  end
end
