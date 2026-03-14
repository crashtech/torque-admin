# frozen_string_literal: true

require 'action_view/renderer/template_renderer'

module Torque
  module Elements
    # = Torque Elements \Frame Renderer
    #
    # This class sits in between the rendering of a template and the layout. It simply give to each part the necessary
    # information to render something in between properly.
    class FrameRenderer < ActionView::TemplateRenderer
      delegate :identifier, to: :@layout
      delegate :virtual_path, to: :@template

      def initialize(frame, layout, options, lookup_context, *lookup_args)
        @frame = frame
        super(lookup_context)

        @details = extract_details(options)
        @template = determine_template({ template: frame })

        @layout = find_layout(layout, lookup_args[1], [formats.first])
      end

      def render(view, locals, &block)
        ActiveSupport::Notifications.instrument(
          'render_frame.action_view',
          identifier: @template.identifier,
          layout: @layout.virtual_path,
          locals: locals,
        ) do
          frame_content = @template.render(view, locals) { |*name| view._layout_for(*name) }
          view.view_flow.set(:layout, frame_content)
          @layout.render(view, locals, &block)
        end
      end
    end
  end
end
