# frozen_string_literal: true

module Torque
  module Admin
    module StreamController
      extend ActiveSupport::Concern

      Key = :"torque@async"

      included do
        class_attribute :stream_actions, instance_writer: false, instance_predicate: false, default: [].freeze
        private_class_method :stream_actions=

        alias_method :process_sync, :process
        include ActionController::Live
        alias_method :process_async, :process
        alias_method :process, :route_processing

        helper_method :process_action_async?, :initialize_async_process

        # Write to the response instead of assigning the body and closing the stream. Content is expected to change with
        # subsequent writes with Turbo-based content updates
        def response_body=(body)
          return super unless process_action_async?

          response.stream.writeln(body)
        end
      end

      class_methods do
        def stream_from_actions(*actions)
          self.stream_actions += actions.flatten.map(&:to_s)
          self.stream_actions.freeze
        end

        def remove_actions_from_stream(*actions)
          self.stream_actions -= actions.flatten.map(&:to_s)
          self.stream_actions.freeze
        end
      end

      def route_processing(action, ...)
        process_action_async?(action) ? process_async(action, ...) : process_sync(action, ...)
      end

      def process_action(...)
        return super unless process_action_async?

        begin
          response.stream.ignore_disconnect = true
          Thread.current[Key] = []
          super
        ensure
          wait_all_async_processes!
          Thread.current[Key] = nil
          response.close unless response.stream.closed?
        end
      end

      protected

        def process_action_async?(name = nil)
          (name.nil? && !Thread.current[Key].nil?) || stream_actions.include?((name || action_name).to_s)
        end

        def wait_all_async_processes!
          return yield unless (processor = admin_application_config.parallel_processing_with)

          error = nil
          Thread.current[Key].each do |process|
            case processor
            when :async
              error ? process.cancel : process.wait
            when :concurrent_ruby
              error ? process.cancel : process.wait!
            end
          rescue Exception => e
            error ||= e
          end

          Thread.current[Key].clear
          Rails.logger.error(error) if error
          # raise error if error
          # TODO: Add support for web console and better errors, guiding turbo to render it as a new page
        end

        def initialize_async_process(&)
          return yield unless (processor = admin_application_config.parallel_processing_with)

          raise +"Async processes cannot be started outside of an async action" if (list = Thread.current[Key]).nil?

          list <<
            case processor
            when :async then Async(&)
            when :concurrent_ruby
              Concurrent::Future.execute(args: Thread.current) do |t1|
                ActiveSupport::IsolatedExecutionState.share_with(t1) do
                  Elements::Context.with(view_context:, &)
                end
              end
            else
              raise "Unknown parallel processing method: #{processor.inspect}"
            end
        end

    end
  end
end
