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

      initializer 'torque-elements.action_view_setup' do
        ActiveSupport.on_load(:action_view) do
          ActionView::LogSubscriber.include(LogSubscriber)
          ActionView::LogSubscriber::Start.prepend(LogSubscriber::Start)

          ActionView::TemplateDetails::Requested.prepend(TemplateDetails::Requested)

          ActionView::LookupContext::DetailsKey.singleton_class.prepend(Templates::RenderContext::Reloader)

          ActionView::AbstractRenderer.prepend(Templates::AbstractRenderer)
          ActionView::LookupContext.prepend(Templates::LookupContext)
        end
      end
    end
  end
end
