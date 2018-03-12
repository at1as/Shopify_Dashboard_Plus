# frozen_string_literal: true

require_relative 'currency'
require_relative 'helpers'
require_relative 'report'

module ShopifyDashboardPlus
  class DiscountReport < Report
    using Currency

    def discount_usage
      discount_value = Hash.new(0.0)
      discount_used  = Hash.new(0)

      @orders.each do |order|
        next unless order.attributes['discount_codes']
        
        order.discount_codes.each do |discount_code|
          discount_value[discount_code.code] = discount_value[discount_code.code].plus(discount_code.amount)
          discount_used[discount_code.code] += 1
        end
      end
      
      {
        :discount_savings => discount_value,
        :top_discount_savings => discount_value.sort_by { |_, v| v }.last,
        :discount_quantity => discount_used,
        :most_used_discount_code => discount_used.sort_by { |_, v| v }.last
      }
    end

    def to_h
      discount_usage
    end
  end
end
