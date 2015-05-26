#!/usr/bin/env ruby

require 'sinatra'
require 'tilt/erubis'
require 'shopify_api'
require 'uri'
require 'chartkick'
require_relative 'shopify_dashboard_plus/version'

configure do
  set :public_dir, "#{__dir__}/../../public"
  set :views, "#{__dir__}/../../views"

  $connected ||= false
  $flash ||= nil
  $metrics ||= false

  HELP = <<-END
  Set global variables through the WebUI or call with the correct ENV variables:
    Example: SHP_KEY=\"<shop_key>\" SHP_PWD=\"<shop_password>\" SHP_NAME=\"<shop_name>\" ./lib/shopify-dashboard.rb
  END

  # Connect if Environment variables were set
  if ENV["SHP_KEY"] && ENV["SHP_PWD"] && ENV["SHP_NAME"]
    API_KEY = ENV["SHP_KEY"]
    PASSWORD = ENV["SHP_PWD"]
    SHOP_NAME = ENV["SHP_NAME"]
    
    begin
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      shop = ShopifyAPI::Shop.current
      $shop_name = SHOP_NAME
      $connected = true
    rescue Exception => e
      puts "\nFailed to connect using provided credentials...(Exception: #{e}\n #{HELP}"
      exit
    end
  end
end


helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  ## Connection & Setup Helpers
  
  # Bind to Shopify Store
  def set_connection(key, pwd, name)
    begin
      shop_url = "https://#{key}:#{pwd}@#{name}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      shop = ShopifyAPI::Shop.current
      $shop_name = name
      open_connection
    rescue
      close_connection
    end
  end

  def close_connection
    $connected = false
  end

  def open_connection
    $connected = true
  end

  def connected?; $connected; end

  def shop_name; $shop_name; end


  ## Generic Helpers
  def date_today
    DateTime.now.strftime('%Y-%m-%d')
  end
  
  def hash_to_list(unprocessed_hash)
    return_list = []
    unprocessed_hash.each {|key, value| return_list.append([key, value])}
  end

  def strip_protocol(page)
    page = page.start_with?('http://') ? page[7..-1] : page
    page = page.start_with?('https://') ? page[8..-1] : page
  end

  def get_host(site)
    host = URI(site).host.downcase
    host = host.start_with?('www.') ? host[4..-1] : host
  end

  # Validate User Date is valid and start date <= end date
  def validate_date_range(from, to)
    interval_start = DateTime.parse(from) rescue nil
    interval_end = DateTime.parse(to) rescue nil

    if interval_start && interval_end
      if interval_start <= interval_end
        return true
      end
    end
    
    false
  end


  ## Metrics Helpers
  def get_total_revenue(orders)
    orders.collect{|order| order.total_price.to_f }.inject(:+).round(2) rescue 0
  end
  
  def get_daily_revenues(start_date, end_date, orders)
    # Create hash entry for total interval over which to inspect sales
    revenue_per_day = {}
    days = DateTime.parse(end_date).mjd - DateTime.parse(start_date).mjd
    (0..days).each{ |day| revenue_per_day[(DateTime.parse(end_date) - day).strftime("%Y-%m-%d")] = 0 }

    # Retreive orders between start and end date (up to 50)
    revenue = orders.collect{|order| [order.created_at, order.total_price.to_f]}
    
    # Filter order details into daily totals and return
    revenue.each do |sale|
      revenue_per_day[DateTime.parse(sale[0]).strftime('%Y-%m-%d')] += sale[1]
    end
    revenue_per_day
  end

  def hash_to_graph_format(sales, merge_results = false)
    
    # ChartKick requires a strange format to build graphs. For instance, an array of
    #   {:name => <item_name>, :data => [[<customer_id>, <item_price>], [<customer_id>, <item_price>]]}
    # places <customer_id> on the independent (x) axis, and stacks each item (item_name) on the y-axis by price (item_price)

    name_hash = sales.collect{|sale| {:name => sale[:name], :data => []}}.uniq
    
    sales.collect do |old_hash|
      name_hash.collect do |new_hash|
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
          consolidated_data[purchase_entry[0]] += purchase_entry[1]
        end
        name_hash[index][:data] = hash_to_list(consolidated_data)
      end
    end

    name_hash
  end
  

  def get_detailed_revenue_metrics(start_date, end_date = DateTime.now)

    desired_fields = ["total_price", "created_at", "billing_address", "currency", "line_items", "customer", "referring_site"]
    revenue_metrics = ShopifyAPI::Order.find(:all, :params => { :created_at_min => start_date + " 0:00",
                                                                :created_at_max => end_date + " 23:59:59",
                                                                :page => 1,
                                                                :limit => 250,
                                                                :fields => desired_fields })

    # Revenue
    total_revenue = get_total_revenue(revenue_metrics)
    avg_revenue  = (total_revenue/(DateTime.parse(end_date).mjd - DateTime.parse(start_date).mjd + 1)).round(2) rescue "N/A"
    daily_revenue = get_daily_revenues(start_date, end_date, revenue_metrics)

    # Countries & Currencies
    currencies = Hash.new(0)
    sales_per_country = Hash.new(0)
    revenue_per_country = []
    revenue_per_country_merged = []

    # Products
    products = Hash.new(0)
    revenue_per_product = Hash.new(0)

    # Prices
    prices = Hash.new(0)
    revenue_per_price_point = Hash.new(0)
    
    # Customers
    customers = []
    customer_sales = []
    customer_sales_unmerged = []
    customer_sales_by_name = []

    # Map customer names to their ID
    customer_details = {} 

    # Referrals
    referring_pages = Hash.new(0)
    referring_sites = Hash.new(0)
    revenue_per_referral_page = Hash.new(0)
    revenue_per_referral_site = Hash.new(0)


    # Iterate thorugh all returned metrics to extract information
    revenue_metrics.each do |order|
      
      if order.attributes['currency']
        currencies[order.currency] += 1
      end
      if order.attributes['billing_address']
        sales_per_country[order.billing_address.country] += 1
      end
      if order.attributes['referring_site']
        if order.attributes['referring_site'].empty?
          referring_pages['None'] += 1
          referring_sites['None'] += 1
        else
          host = get_host(order.referring_site)
          page = strip_protocol(order.referring_site)
          referring_pages[page] += 1
          referring_sites[host] += 1
        end
        order.line_items.each do |line_item|
          if order.attributes['referring_site'].empty?
            revenue_per_referral_page['None'] += line_item.price.to_f rescue 0
            revenue_per_referral_site['None'] += line_item.price.to_f rescue 0
          else
            host = get_host(order.referring_site)
            page = strip_protocol(order.referring_site)
            revenue_per_referral_site[host] += line_item.price.to_f.round(2) rescue 0
            revenue_per_referral_page[page] += line_item.price.to_f.round(2) rescue 0
          end
        end
      end

      # Remove trailing digits (ex. 44.95.round(2) + 940.6.round(2) = 985.5500000000001)
      # Note that if the sample has 100_000_000_000 entries, the precision will
      # begin to round up cents. There is a safer way to accomplish this
      revenue_per_referral_site.map{|key, value| [key, value.round(2)] }.to_h
      revenue_per_referral_page.map{|key, value| [key, value.round(2)] }.to_h


      # Iterate over order line items for: product name, product price & customer id
      # Use to populate: products, prices, revenue_per_price_point, revenue_per_product,
      #                  revenue_per_country, customer_sales, and to map customer name to id
      order.line_items.each do |line_item|
        products[line_item.title] += 1
        prices[line_item.price] += 1

        # TODO: Clean up precision
        revenue_per_price_point[line_item.price] += line_item.price.to_f.round(2) rescue 0
        revenue_per_product[line_item.title] += line_item.price.to_f.round(2) rescue 0
        
        # Store customer as "<firstname> <lastname> (<email>)" such that uniqueness is gaurenteed
        customer_name = "#{order.customer.first_name} #{order.customer.last_name} (#{order.customer.email})"

        revenue_per_country.push({:name => line_item.title, 
                                  :data => [order.billing_address.country, line_item.price.to_f]})
        
        customer_sales.push({ :name => line_item.title,
                              :data => [customer_name, line_item.price.to_f]})
      end

      # Format data for display with chartkick
      revenue_per_country_merged = hash_to_graph_format(revenue_per_country, true)
      customer_sales_unmerged = hash_to_graph_format(customer_sales)

    end

    metrics = { :currencies => currencies,
                :sales_per_country => sales_per_country,
                :revenue_per_country => revenue_per_country_merged,
                :products => products,
                :prices => (prices.sort_by{|x,y| x.to_f }.to_h rescue {}),
                :customer_sales => customer_sales_unmerged,
                :referring_sites => (referring_sites.sort().to_h rescue {}),
                :referring_pages => (referring_pages.sort().to_h rescue {}),
                :revenue_per_referral_site => (revenue_per_referral_site.sort().to_h rescue {}),
                :revenue_per_referral_page => (revenue_per_referral_page.sort().to_h rescue {}),
                :total_revenue => total_revenue,
                :average_revenue => avg_revenue,
                :daily_revenue => daily_revenue,
                :revenue_per_product => revenue_per_product,
                :revenue_per_price_point => (revenue_per_price_point.sort_by{|x,y| x.to_f }.to_h rescue {})
              }

    return metrics
  end
end

before do
  $flash = nil
  $metrics = false
end


get '/' do
  redirect '/connect' unless connected?

  # If no start date is set, default to match end date
  # If no date parameters are set, default both to today
  @today = date_today
  from = (params[:from] if not params[:from].empty? rescue nil) || (params[:to] if not params[:to].empty? rescue nil) || @today
  to = (params[:to] if not params[:to].empty? rescue nil) || @today

  if validate_date_range(from, to)
    @metrics = get_detailed_revenue_metrics(from, to)
    $metrics = true
  else
    $flash = "Invalid Dates. Please use format YYYY-MM-DD"
  end
  
  erb :report
end

get '/connect' do
  erb :connect
end

post '/connect' do
  set_connection(params[:api_key], params[:api_pwd], params[:shop_name])
  
  if connected?
    redirect '/'
  else
    $flash = "Failed to Connect..."
    erb :connect
  end
end

post '/disconnect' do
  API_KEY, API_PWD, SHP_NAME = "", "", ""
  close_connection

  erb :connect
end

## Kills process (work around for Vegas Gem not catching SIGINT)
post '/quit' do
  redirect to('/'), 200
end

after '/quit' do
  puts "\nExiting..."
  exit!
end
