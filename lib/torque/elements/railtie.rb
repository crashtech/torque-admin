# frozen_string_literal: true

require 'rails/railtie'

require_relative 'railtie/log_subscriber'
require_relative 'railtie/template_details'

require_relative 'templates/render_context'

module Torque
  module Elements
    # = Torque Elements Railtie
    #
    # Rails integration and configuration
    class Railtie < ::Rails::Railtie
      config.eager_load_namespaces << Torque::Elements

      initializer 'torque-elements.default_attributes' do
        Elements.define_attribute('@content', ContentHandler.new)

        Elements.define_attribute('remove_if', Elements.define_attribute('if', ContentHandler.new))
        Elements.define_attribute('remove_unless', Elements.define_attribute('unless', ContentHandler.new))

        Elements.define_attribute('style', MapHandler.new(separator: ';', format: :dasherize, as_json: false))
        Elements.define_attribute('class', ListHandler.new)
        # Elements.define_attribute('name', FormatHandler.new('[%s]', include_first: false))

        if defined?(Stimulus::Engine)
          Elements.define_attribute('data-controller', ListHandler.new(nested_separator: '--'))
          Elements.define_attribute('data-action', ListHandler.new(nested_separator: '#'))

          Elements.define_attribute(/\Adata-.*-target\z/, RefHandler.new(format: :lower_camel_case))
        end
      end

      initializer 'torque-elements.action_view_setup' do
        ActiveSupport.on_load(:action_view) do
          ActionView::LogSubscriber.include(LogSubscriber)
          ActionView::LogSubscriber::Start.prepend(LogSubscriber::Start)

          ActionView::TemplateDetails::Requested.prepend(TemplateDetails::Requested)

          ActionView::LookupContext::DetailsKey.singleton_class.prepend(Templates::RenderContext::Reloader)

          ActionView::AbstractRenderer.prepend(Templates::AbstractRenderer)
          ActionView::LookupContext.prepend(Templates::LookupContext)

          ActionView::Base.prepend(Helpers::HookContext)
        end
      end

      initializer 'torque-elements.action_controller_setup' do
        ActiveSupport.on_load(:action_controller) do
          ActionController::Base::PROTECTED_IVARS.concat(%i[@_action_has_frame @_current_frame @_renders_templates])
        end
      end

      initializer 'torque-elements.add_helpers' do
        ActiveSupport.on_load(:action_view) { include Elements::Helpers }
      end
    end
  end
end
