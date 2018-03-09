# frozen_string_literal: true

require_relative 'helpers'

module ShopifyDashboardPlus
  class Report
    include ApplicationHelpers

    def initialize(orders)
      @orders     = orders
      @line_items = orders.flat_map { |order| order.line_items.map { |line_item| line_item } }
    end
  end
end
