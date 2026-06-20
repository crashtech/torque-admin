# frozen_string_literal: true

require_relative 'frame/renderer'

module Torque
  module Elements
    # = Torque Elements \Frame
    #
    # Adds an additional layer between views and templates, sitting in the middle of both rendering and execution. The
    # intent is for it to manage the BODY main structure, before defining where the content will be rendered.
    #
    # Besides that, it is a almost direct copy of +ActionView::Layouts+, with just its own name.
    module Frame
      extend ActiveSupport::Concern

      included do
        class_attribute :_frame, instance_accessor: false
        helper_method :current_frame
        _write_frame_method
      end

      class_methods do
        def inherited(klass)
          super
          klass._write_frame_method
        end

        # Specify the frame to use for this class.
        #
        # If the specified frame is a:
        # String:: the String is the template name
        # Symbol:: call the method specified by the symbol
        # Proc::   call the passed Proc
        # false::  There is no frame
        # true::   raise an ArgumentError
        # nil::    Force default frame behavior with inheritance
        #
        # Return value of +Proc+ and +Symbol+ arguments should be +String+, +false+, +true+, or +nil+
        # with the same meaning as described above.
        #
        # ==== Parameters
        #
        # * <tt>frame</tt> - The frame to use.
        def frame(frame, only: nil, except: nil)
          self._frame = frame
          _write_frame_method

          if only || except
            before_action do
              @_action_has_frame = Array.wrap(only).map(&:to_s).include?(action_name) if only
              @_action_has_frame ||= Array.wrap(except).map(&:to_s).exclude?(action_name) if except
            end
          end
        end

        def _write_frame_method
          frame_definition =
            case _frame
            when String then _frame.inspect
            when Symbol
              <<~RUBY
                #{_frame}.tap do |frame|
                  return if frame.nil?
                  unless frame.is_a?(String) || !frame
                    raise ArgumentError, <<~MSG.squish
                      Your frame method :#{_frame} returned \#{frame}.
                      It should have returned a String, false, or nil
                    MSG
                  end
                end
              RUBY
            when Proc
              define_method :_frame_from_proc, &_frame
              private :_frame_from_proc
              "_frame_from_proc(#{_frame.arity == 0 ? '' : 'self'})"
            when false then nil
            else 'super'
            end

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            # frozen_string_literal: true
            def _frame(lookup_context, formats, keys)
              #{frame_definition}
            end
            private :_frame
          RUBY
        end
      end

      def _process_render_template_options(options)
        super

        if _include_frame?(options)
          frame = options.delete(:frame) { :default }
          # Replace layout so it sits right in between the template and the real layout
          options[:layout] = _frame_for_renderer(options, _frame_for_option(frame))
        end
      end

      attr_internal_writer :action_has_frame

      def initialize(*)
        @_action_has_frame = true
        super
      end

      def action_has_frame?
        @_action_has_frame
      end

      protected

        def current_frame
          defined?(@_current_frame) && @_current_frame&.to_s
        end

      private

        def _frame(*)
          # This will be overwritten by _write_frame_method
        end

        def _frame_for_option(name)
          case name
          when String     then _normalize_frame(name)
          when Proc       then name
          when true       then proc { |*args| _default_frame(*args, true) }
          when :default   then proc { |*args| _default_frame(*args, false) }
          when false, nil then nil
          else
            raise ArgumentError, <<~MSG.squish
              String, Proc, :default, true, or false, expected for `frame'; you passed #{name.inspect}
            MSG
          end
        end

        def _normalize_frame(value)
          value.is_a?(String) && !value.match?(/\bframes/) ? "frames/#{value}" : value
        end

        def _default_frame(lookup_context, formats, keys, require_frame = false)
          begin
            value = _frame(lookup_context, formats, keys) if action_has_frame?
          rescue NameError => e
            raise e, "Could not render frame: #{e.message}"
          end

          if require_frame && action_has_frame? && !value
            raise ArgumentError, "There was no default frame for #{self.class} in #{view_paths.inspect}"
          end

          _normalize_frame(value)
        end

        def _include_frame?(options)
          !options.keys.intersect?(%i[body plain html inline partial]) || options.key?(:frame)
        end

        def _frame_for_renderer(options, frame)
          layout = options.delete(:layout)
          return layout unless frame && layout

          proc do |*args|
            @_current_frame = resolved_frame = frame.respond_to?(:call) ? frame.call(*args) : frame
            layout = FrameRenderer.new(resolved_frame, layout, options, *args) if resolved_frame
            layout
          end
        end

    end
  end
end
