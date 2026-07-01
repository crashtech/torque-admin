# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Rendering Helpers
    class UiBuilder
      module Rendering
        def render_content_tag(tag_name, content = nil, options = {}, &)
          content = view_context.capture(&) if block_given?
          combine_option('@content', options, content) if content.present?
          render_tag(tag_name, options, with_content: true)
        end

        def render_tag(tag_name, options = {}, with_content: false)
          options = collapse_options(options)
          return if removed_from_options(options)

          left, *inner, right = options.delete('@content')&.values_at(*ContentHandler::PARTS)
          content = view_context.safe_join(inner.flatten) if with_content && inner.present?
          content = tag_builder.public_send(tag_name, *content, **options)
          return content if left.nil? && right.nil?

          view_context.safe_join([*left, content, *right])
        end
      end
    end
  end
end
