# frozen_string_literal: true

require_relative 'currency'
require_relative 'helpers'
require_relative 'report'

module ShopifyDashboardPlus
  class RevenueReport < Report
    using Currency

    def revenue_per_country
      revenue_per_country = []
      @orders.each do |order|
        order.line_items.each do |item|
          revenue_per_country.push(
            :name => item.title,
            :data => [order.billing_address.country, item.price.to_f]
          )
        end
      end
      
      hash_to_graph_format(revenue_per_country, merge_results: true)
    end

    def revenue_per_price_point
      revenue_per_price_point = Hash.new(0)
      @line_items.each do |item|
        revenue_per_price_point[item.price] = revenue_per_price_point[item.price].plus(item.price)
      end
 
      revenue_per_price_point.sort_by { |x, _| x.to_f }.to_h
    rescue
      {}
    end

    def revenue_per_product
      revenue_per_product = Hash.new(0.0)
      @line_items.each do |item|
        revenue_per_product[item.title] = revenue_per_product[item.title].plus(item.price)
      end
 
      revenue_per_product
    end

    def to_h
      {
        :revenue_per_country      => revenue_per_country,
        :revenue_per_product      => revenue_per_product,
        :top_grossing_product     => revenue_per_product.sort_by { |_, v| v }.last,
        :revenue_per_price_point  => revenue_per_price_point,
        :top_grossing_price_point => revenue_per_price_point.sort_by { |_, v| v }.last
      }
    end
  end
end
