# frozen_string_literal: true

module ApplicationHelpers

  include Rack::Utils
  alias_method :h, :escape_html

  DESIRED_FIELDS = %w[
    total_price
    created_at
    billing_address
    currency
    line_items
    customer
    referring_site
    discount_codes
  ].freeze

  ## Authentication Helpers
  def authenticated?
    session[:logged_in]
  end


  ## Connection & Setup Helpers
  
  def set_connection(key, pwd, name)
    ShopifyAPI::Base.site = "https://#{key}:#{pwd}@#{name}.myshopify.com/admin"
    shop = ShopifyAPI::Shop.current
    
    $shop_name = name
    $currency  = shop.money_with_currency_format
    open_connection
  rescue => e
    puts "Exception: #{e}"
    close_connection
  end

  def close_connection
    $connected = false
    session[:logged_in] = nil
  end

  def open_connection
    $connected = true
    session[:logged_in] = true
  end

  def connected?
    $connected
  end

  def shop_name
    $shop_name
  end


  ## Generic Helpers

  def date_today
    DateTime.now.strftime('%Y-%m-%d')
  end

  def pluralize(num, singular, plural)
    num.to_i == 1 ? "#{num} #{singular.capitalize}" : "#{num} #{plural.capitalize}"
  end

  def strip_protocol(page)
    page.sub(/\Ahttps?:\/\//, "")
  end

  def get_host(site)
    URI(site).host.downcase.sub(/\Awww\./, "")
  end

  def date_range_valid?(from, to)
    DateTime.parse(from) <= DateTime.parse(to)
  rescue ArgumentError
    false
  end


  ## Metrics Helpers

  def max_hash_key_exclude_value(unsorted_hash, exclude_value)
    unsorted_hash.sort_by{ |k, v| v }.map{ |k, v| [k, v] unless k.downcase == exclude_value }.compact.last
  end

  def display_as_currency(value)
    $currency.gsub("{{amount}}", value.to_s)
  rescue
    'N/A'
  end

  def get_date_range(first, last)
    DateTime.parse(last).mjd - DateTime.parse(first).mjd
  end

  def get_total_revenue(orders)
    totals = orders.map { |order| order.total_price.to_f }
    totals.inject(:+).round(2)
  rescue
    0
  end

  def get_average_revenue(total_revenue, duration)
    (total_revenue/duration).round(2)
  rescue
    'N/A'
  end
  
  def get_daily_revenues(start_date, end_date, orders)
    # Create hash entry for every day within interval over which to inspect sales
    revenue_per_day = {}
    days = get_date_range(start_date, end_date)
    (0..days).each { |day| revenue_per_day[(DateTime.parse(end_date) - day).strftime("%Y-%m-%d")] = 0 }

    # Retreive array of ActiveRecord::Collections, each containing orders between the start and end date
    order_details = orders.map { |order| [order.created_at, order.total_price.to_f] }
    
    # Filter order details into daily totals and return
    order_details.each do |(date, total)|
      day_index = DateTime.parse(date).strftime('%Y-%m-%d')
      revenue_per_day[day_index] = revenue_per_day[day_index].plus(total)
    end
    
    revenue_per_day
  end

  def hash_to_graph_format(sales, merge_results: false)
    
    # ChartKick requires a strange format to build graphs. For instance, an array of
    #   {:name => <item_name>, :data => [[<customer_id>, <item_price>], [<customer_id>, <item_price>]]}
    # places <customer_id> on the independent (x) axis, and stacks each item (item_name) on the y-axis by price (item_price)

    name_hash = sales.map{ |sale| {:name => sale[:name], :data => []} }.uniq
    
    sales.map do |old_hash|
      name_hash.map do |new_hash|
        if old_hash[:name] == new_hash[:name]
          new_hash[:data].push(old_hash[:data])
        end
      end
    end

    # This hash will return repeated values (i.e., :data => [["item 1", 6], ["item 1", 6]])
    # ChartKick will ignore repeated entries, so the totals need to be merged
    # i.e., :data => [["item1", 12]]
    if merge_results
      name_hash.each_with_index do |item, index|
        consolidated_data = Hash.new(0)
        item[:data].each do |purchase_entry|
          consolidated_data[purchase_entry[0]] = consolidated_data[purchase_entry[0]].plus(purchase_entry[1])
        end
        name_hash[index][:data] = consolidated_data.to_a
      end
    end

    name_hash
  end

  # Return order query parameters hash
  def order_parameters_paginate(start_date, end_date, page)
    {  
      :created_at_min => start_date + " 0:00", 
      :created_at_max => end_date + " 23:59:59", 
      :limit  => 250,
      :page   => page,
      :fields => DESIRED_FIELDS 
    }
  end


  # Return array of ActiveRecord::Collections, each containing up to :limit (250) orders
  # Continue to query next page until less than :limit orders are returned, indicating no next pages with orders matching query
  def get_list_of_orders(start_date, end_date)

    # Get first 250 results matching query
    params = order_parameters_paginate(start_date, end_date, 1)
    revenue_metrics = [ShopifyAPI::Order.find(:all, :params => params)]

    # If the amount of results equal to the limit (250) were returned, pass the query on to the next page (orders 251 to 500)
    while revenue_metrics.last.length == 250
      params = order_parameters_paginate(start_date, end_date, revenue_metrics.length + 1)
      revenue_metrics << ShopifyAPI::Order.find(:all, :params => params)
    end

    revenue_metrics.flat_map{ |orders| orders.map{ |order| order }}
  end
  

  def get_detailed_revenue_metrics(start_date, end_date = DateTime.now)

    order_list = get_list_of_orders(start_date, end_date)

    # Revenue
    total_revenue = get_total_revenue(order_list)
    duration = get_date_range(start_date, end_date) + 1
    avg_revenue = get_average_revenue(total_revenue, duration)
    daily_revenue = get_daily_revenues(start_date, end_date, order_list)
    max_daily_revenue = daily_revenue.max_by{ |k,v| v }[1]
    
    # Retrieve Metrics
    sales_report = ShopifyDashboardPlus::SalesReport.new(order_list).to_h
    revenue_report = ShopifyDashboardPlus::RevenueReport.new(order_list).to_h
    traffic_report = ShopifyDashboardPlus::TrafficReport.new(order_list).to_h
    discounts_report = ShopifyDashboardPlus::DiscountReport.new(order_list).to_h
    metrics = { 
      :total_revenue     => total_revenue,
      :average_revenue   => avg_revenue,
      :daily_revenue     => daily_revenue,
      :max_daily_revenue => max_daily_revenue,
      :duration          => duration
    }

    [sales_report, revenue_report, traffic_report, discounts_report, metrics].inject(&:merge)
  end

end

