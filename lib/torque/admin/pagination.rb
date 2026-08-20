# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Pagination
    class Pagination
      extend ActiveSupport::Autoload

      autoload :Pagy
      autoload :Kaminari

      MODES = %i[page cursor].freeze

      class_attribute :default_per, instance_accessor: false, default: 100
      class_attribute :default_per_options, instance_accessor: false

      attr_reader :page, :per, :mode, :per_options, :count, :pages, :previous, :next

      class << self
        def build(adapter, **)
          klass = adapter.nil? ? self : const_get(adapter.to_s.camelize)
          klass.new(**)
        end
      end

      def initialize(page: nil, per: nil, mode: :page, per_options: nil, href: nil, per_href: nil)
        raise ArgumentError, "Unknown pagination mode: #{mode.inspect}" unless MODES.include?(mode)

        @mode = mode
        @page = page.to_i
        @per = per.to_i
        @per_options = per_options || self.class.default_per_options

        @page = 1 unless @page.positive?
        @per = self.class.default_per unless @per.positive? && !@per_options&.exclude?(@per)

        @href = href
        @per_href = per_href
      end

      def cursor?
        mode == :cursor
      end

      def first?
        page == 1
      end

      def last?
        self.next.nil?
      end

      def href(page)
        @href&.call(page)
      end

      def per_href(per)
        @per_href&.call(per)
      end

      def apply(scope)
        @count = scope.count unless cursor?
        @pages = [(count / per.to_f).ceil, 1].max if count
        @previous = page - 1 if page > 1
        @next = page + 1 if next?(scope)
        scope.offset(offset).limit(per)
      end

      protected

        def offset
          (page - 1) * per
        end

        def next?(scope)
          cursor? ? scope.offset(page * per).exists? : page < pages
        end
    end
  end
end
