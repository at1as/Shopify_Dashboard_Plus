require_relative 'helpers'

module ShopifyDashboardPlus

  class Report
    include ApplicationHelpers

    def initialize(orders)
      @orders = orders
      @line_items = orders.flat_map{ |order| order.line_items.map { |line_item| line_item }}
    end
  end


  class SalesReport < Report
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
          customer_sales.push({ :name => item.title,
                                :data => [customer_name, item.price.to_f]})
        end
      end
      hash_to_graph_format(customer_sales)
    end

    def sales_per_price_point
      sales_per_price_point = Hash.new(0)

      @line_items.each do |item|
        sales_per_price_point[item.price] += 1
      end
      sales_per_price_point.sort_by{ |x,y| x.to_f }.to_h rescue {}
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
        :sales_per_country => sales_per_country,
        :sales_per_price => sales_per_price_point,
        :sales_per_product => sales_per_product,
        :sales_per_customer => sales_per_customer,
        :number_of_sales => number_of_sales
      }
    end
  end


  class RevenueReport < Report
    def revenue_per_country
      revenue_per_country = []
      @orders.each do |order|
        order.line_items.each do |item|
          revenue_per_country.push({:name => item.title, 
                                    :data => [order.billing_address.country, item.price.to_f]})
        end
      end
      hash_to_graph_format(revenue_per_country, merge_results: true)
    end

    def revenue_per_price_point
      revenue_per_price_point = Hash.new(0)
      @line_items.each do |item|
        revenue_per_price_point[item.price] = revenue_per_price_point[item.price].plus(item.price)
      end
      revenue_per_price_point.sort_by{ |x,y| x.to_f }.to_h rescue {}
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
        :revenue_per_country => revenue_per_country,
        :revenue_per_product => revenue_per_product,
        :revenue_per_price_point => revenue_per_price_point,
      }
    end
  end


  class DiscountReport < Report

    def discount_usage
      discount_value, discount_used = Hash.new(0.0), Hash.new(0)

      @orders.each do |order|
        if order.attributes['discount_codes']
          order.discount_codes.each do |discount_code|
            discount_value[discount_code.code] = discount_value[discount_code.code].plus(discount_code.amount)
            discount_used[discount_code.code] += 1
          end
        end
      end
      {
        :discount_savings => discount_value,
        :discount_quantity => discount_used
      }
    end

    def to_h
      discount_usage
    end
  end


  class TrafficReport < Report

    def number_of_referrals
      referring_sites, referring_pages = Hash.new(0), Hash.new(0)

      @orders.each do |order|
        if order.attributes['referring_site'].empty?
          referring_pages['None'] += 1
          referring_sites['None'] += 1
        else
          host = get_host(order.referring_site)
          page = strip_protocol(order.referring_site)
          referring_pages[page] += 1
          referring_sites[host] += 1
        end
      end
      {
        :referral_sites => (referring_sites.sort().to_h rescue {}),
        :referral_pages => (referring_pages.sort().to_h rescue {})
      }
    end

    def traffic_revenue
      revenue_per_referral_page, revenue_per_referral_site = Hash.new(0.0), Hash.new(0.0)

      @orders.each do |order|
        order.line_items.each do |item|
          if order.attributes['referring_site'].empty?
            revenue_per_referral_page['None'] = revenue_per_referral_page['None'].plus(item.price)
            revenue_per_referral_site['None'] = revenue_per_referral_site['None'].plus(item.price)
          else
            host = get_host(order.referring_site)
            page = strip_protocol(order.referring_site)
            revenue_per_referral_site[host] = revenue_per_referral_site[host].plus(item.price)
            revenue_per_referral_page[page] = revenue_per_referral_page[page].plus(item.price)
          end
        end
      end
      {
        :revenue_per_referral_site => revenue_per_referral_site.sort().to_h,
        :revenue_per_referral_page => revenue_per_referral_page.sort().to_h
      }
    end

    def to_h
      traffic_revenue.merge(number_of_referrals)
    end
  end

end