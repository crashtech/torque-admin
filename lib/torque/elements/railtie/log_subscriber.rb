# frozen_string_literal: true

module Torque
  module Elements
    module LogSubscriber
      extend ActiveSupport::Concern

      included do
        subscribe_log_level :render_frame, :debug
        add_event_subscriber :render_frame

        subscribe_log_level :precompile_template, :debug
        add_event_subscriber :precompile_template
      end

      def render_frame(event)
        info do
          message = +"  Rendered #{from_rails_root(event.payload[:identifier])}"
          message << " within #{from_rails_root(event.payload[:layout])}"
          message << " (Duration: #{event.duration.round(1)}ms | GC: #{event.gc_time.round(1)}ms)"
        end
      end

      def precompile_template(event)
        info do
          message = +"  Compiled template #{from_rails_root(event.payload[:identifier]).delete_prefix('app/templates/')}"
          message << " (Duration: #{event.duration.round(1)}ms | GC: #{event.gc_time.round(1)}ms)"
        end
      end
    end

    module LogSubscriber::Start
      extend ActiveSupport::Concern

      prepended do
        ActiveSupport::Notifications.subscribe("render_frame.action_view", new)
        ActiveSupport::Notifications.subscribe("precompile_template.action_view", new)
      end

      def start(name, id, payload)
        return unless logger

        case name
        when 'render_frame.action_view'
          logger.debug do
            message = +"  Rendering frame #{from_rails_root(payload[:identifier])}"
            message << " within #{from_rails_root(payload[:layout])}"
          end
        when 'precompile_template.action_view'
          logger.debug do
            +"  Compiling template #{from_rails_root(payload[:identifier]).delete_prefix('app/templates/')}"
          end
        else super
        end
      end
    end
  end
end
