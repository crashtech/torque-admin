# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Pagination Element
    class PaginationElement < ButtonsElement
      node :per, as: :link

      setting :window

      attr_reader :pagination

      def initialize(name, *, pagination:, **, &)
        @pagination = pagination
        super(name, *, **, &)
      end

      def import_from_pagination(window: settings(:window, 2))
        item(:first, pagination.href(1), disabled: pagination.first?)
        item(:previous, pagination.href(pagination.previous), disabled: pagination.first?)
        import_pages(window) if pagination.pages
        item(:next, pagination.href(pagination.next), disabled: pagination.last?)
        item(:last, pagination.href(pagination.pages), disabled: pagination.last?) if pagination.pages
      end

      def import_per_options
        pagination.per_options.to_a.each do |value|
          per(:"per_#{value}", href: pagination.per_href(value), label: value.to_s, active: value == pagination.per)
        end
      end

      protected

        def import_pages(window)
          current = pagination.page
          pages = [1, *(current - window..current + window), pagination.pages].select { |page| page.between?(1, pagination.pages) }.uniq
          pages.each_with_index do |page, index|
            item(:"gap_#{page}", nil, label: '…', disabled: true) if index.positive? && page - pages[index - 1] > 1
            item(:"page_#{page}", pagination.href(page), label: page.to_s, active: page == current)
          end
        end
    end
  end
end
