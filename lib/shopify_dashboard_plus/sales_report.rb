# frozen_string_literal: true

require_relative 'helpers'
require_relative 'report'

module ShopifyDashboardPlus
  class SalesReport < Report
    using Currency
    
    def sales_per_country
      sales_per_country = Hash.new(0)

      @orders.each do |order|
        sales_per_country[order.billing_address.country] += 1 if order.attributes['billing_address']
      end
      
      sales_per_country
    end

    def sales_per_product
      sales_per_product = Hash.new(0)

      @line_items.each do |item|
        sales_per_product[item.title] += 1
      end

      sales_per_product
    end

    def sales_per_customer
      customer_sales = []
      @orders.each do |order|
        order.line_items.each do |item|
          customer_name = "#{order.customer.first_name} #{order.customer.last_name} (#{order.customer.email})"
          customer_sales.push(
            :name => item.title,
            :data => [customer_name, item.price.to_f]
          )
        end
      end
      
      hash_to_graph_format(customer_sales)
    end

    def sales_per_price_point
      sales_per_price_point = Hash.new(0)

      @line_items.each do |item|
        sales_per_price_point[item.price] += 1
      end
      
      sales_per_price_point.sort_by { |x, _| x.to_f }.to_h
    rescue
      {}
    end

    def number_of_sales
      @orders.length
    end

    def currencies_per_sale
      currencies = Hash.new(0)

      @orders.each do |order|
        currencies[order.currency] += 1 if order.attributes['currency']
      end
      
      currencies
    end

    def to_h
      {
        :currencies_per_sale => currencies_per_sale,
        :most_used_currency => currencies_per_sale.sort_by { |_, v| v }.last,
        :sales_per_country => sales_per_country,
        :most_sales_per_country => sales_per_country.sort_by { |_, v| v }.last,
        :sales_per_price => sales_per_price_point,
        :top_selling_price_point => sales_per_price_point.sort_by { |_, v| v }.last,
        :sales_per_product => sales_per_product,
        :top_selling_product => sales_per_product.sort_by { |_, v| v }.last,
        :sales_per_customer => sales_per_customer,
        :number_of_sales => number_of_sales
      }
    end
  end
end
