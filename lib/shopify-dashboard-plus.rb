#!/usr/bin/env ruby

require 'sinatra'
require 'tilt/erubis'
require 'shopify_api'
require 'uri'
require 'chartkick'


configure do
  set :public_dir, File.expand_path('../../public', __FILE__)
  set :views, File.expand_path('../../views', __FILE__)

  $connected ||= false

  HELP = "Set global environment variables before calling script, or call with ENV variables: \
  \t\nExample: SHP_KEY=\"<shop_key>\" SHP_PWD=\"<shop_password>\" SHP_NAME=\"<shop_name>\" ./lib/shopify-dashboard.rb\n"

  # Connect if Environment variables were set
  if ENV["SHP_KEY"] && ENV["SHP_PWD"] && ENV["SHP_NAME"]
    API_KEY = ENV["SHP_KEY"]
    PASSWORD = ENV["SHP_PWD"]
    SHOP_NAME = ENV["SHP_NAME"]
    
    begin
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      puts shop_url
      shop = ShopifyAPI::Shop.current
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

  # Connection Helpers
  def set_connection(key, pwd, name)
    begin
      shop_url = "https://#{key}:#{pwd}@#{name}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      shop = ShopifyAPI::Shop.current
      connection_open
      puts "YESSSS #{connected?}"
    rescue
      connection_closed
    end
  end

  def connection_closed
    $connected = false
  end

  def connection_open
    $connected = true
  end

  def connected?
    $connected
  end


  # Generic Helpers
  def hash_to_list(unprocessed_hash)
    return_list = []
    unprocessed_hash.each do |key, value|
      return_list.append([key, value])
    end
  end

  def date_today
    DateTime.now.strftime('%Y-%m-%d')
  end


  # Metrics Helpers
  def get_total_revenue(orders)
    revenue = orders.collect{|order| order.total_price.to_f }.inject(:+).round(2) rescue 0
    revenue ||= 0
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

  def hash_to_graph_format(sales)
    
    # ChartKick requires a strange format to build graphs. For instance, an array of
    #   {:name => <item_name>, :data => [[<customer_id>, <item_price>], [<customer_id>, <item_price>]]}
    # places <customer_id> on the independent (x) axis, and stacks item each item by y-axis by price

    # This hash will return repeated values (i.e., :data => [["item 1", 6], ["item 1", 6]])
    # ChartKick will ignore repeated entries. Use `format_hash_for_stacked_graph_repeat` to merge entries before submission

    name_hash = sales.collect{|sale| {:name => sale[:name], :data => []}}.uniq
    
    sales.collect do |old_hash|
      name_hash.collect do |new_hash|
        if old_hash[:name] == new_hash[:name]
          new_hash[:data].push(old_hash[:data])
        end
      end
    end

    name_hash
  end


  def hash_to_graph_format_merge(sales)
    
    # ChartKick requires an annoying format to build graphs. For instance, an array of entries formated as
    #   { :name => <item_name>, :data => [[<customer_id>, <item_price>], [<customer_id>, <item_price>]] }
    # places <customer_id> on the independent (x) axis, and stacks item each item by y-axis by price

    name_hash = sales.collect{|sale| {:name => sale[:name], :data => []}}.uniq
    
    sales.collect do |old_hash|
      name_hash.collect do |new_hash|
        if old_hash[:name] == new_hash[:name]
          new_hash[:data].push(old_hash[:data])
        end
      end
    end

    # name_hash may contain repeated values (i.e., :data => [["item 1", 6], ["item 1", 6]])
    # ChartKick will ignore repeated entries, so they need to be consolidated
    # i.e., :data => [["item1", 12]]

    name_hash.each_with_index do |item, index|
      consolidated_data = Hash.new(0)
      item[:data].each do |purchase_entry|
        consolidated_data[purchase_entry[0]] += purchase_entry[1]
      end
      name_hash[index][:data] = hash_to_list(consolidated_data)
    end

    name_hash
  end
  

  def get_detailed_revenue_metrics(start_date, end_date = DateTime.now)
    desired_fields = ["total_price", "created_at", "billing_address", "currency", "line_items", "customer", "referring_site"]
    revenue_metrics = ShopifyAPI::Order.find(:all, :params => { :created_at_min => start_date, 
                                                                :created_at_max => end_date, 
                                                                :fields => desired_fields })
    
    # Revenue
    total_revenue = get_total_revenue(revenue_metrics)
    avg_revenue = (total_revenue/(DateTime.parse(end_date).mjd - DateTime.parse(start_date).mjd + 1)).round(2) rescue "N/A"
    daily_revenue = get_daily_revenues(start_date, end_date, revenue_metrics)

    # Countries & Currencies
    currencies = Hash.new(0)
    sales_per_country = Hash.new(0)
    revenue_per_country = []
    revenue_per_country_uniq = []

    # Products
    products = Hash.new(0)
    revenue_per_product = Hash.new(0)

    # Prices
    prices = Hash.new(0)
    revenue_per_price_point = Hash.new(0)
    
    # Customers
    customers = []
    customer_sales = []
    customer_sales_uniq = []

    # Referrals
    referring_pages = Hash.new(0)
    referring_sites = Hash.new(0)
    revenue_per_referral_page = Hash.new(0)
    revenue_per_referral_site = Hash.new(0)

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
          host = URI(order.referring_site).host
          referring_pages[order.referring_site] += 1
          referring_sites[host] += 1
        end
        order.line_items.each do |line_item|
          if order.attributes['referring_site'].empty?
            revenue_per_referral_page['None'] += line_item.price.to_f
            revenue_per_referral_site['None'] += line_item.price.to_f
          else
            host = URI(order.referring_site).host
            revenue_per_referral_page[order.referring_site] += line_item.price.to_f
            revenue_per_referral_site[host] += line_item.price.to_f
          end
        end
      end

      order.line_items.each do |line_item|
        products[line_item.title] += 1
        prices[line_item.price] += 1
        revenue_per_price_point[line_item.price] += line_item.price.to_f
        revenue_per_product[line_item.title] += line_item.price.to_f
        
        revenue_per_country.push({:name => line_item.title, :data => [order.billing_address.country, line_item.price.to_f]})
        customer_sales.push({:name => line_item.title, :data => [order.customer.id.to_s, line_item.price.to_f]})
      end

      customer_sales_uniq = hash_to_graph_format(customer_sales)
      revenue_per_country_uniq = hash_to_graph_format_merge(revenue_per_country)
    end

    metrics = { :currencies => currencies,
                :sales_per_country => sales_per_country,
                :revenue_per_country => revenue_per_country_uniq,
                :products => products,
                :prices => prices.sort_by{|x,y| x.to_f }.to_h,
                :customer_sales => customer_sales_uniq,
                :referring_sites => referring_sites.sort().to_h,
                :referring_pages => referring_pages.sort().to_h,
                :revenue_per_referral_site => revenue_per_referral_site.sort().to_h,
                :revenue_per_referral_page => revenue_per_referral_page.sort().to_h,
                :total_revenue => total_revenue,
                :average_revenue => avg_revenue,
                :daily_revenue => daily_revenue,
                :revenue_per_product => revenue_per_product,
                :revenue_per_price_point => revenue_per_price_point.sort_by{|x,y| x.to_f }.to_h
              }

    return metrics
  end
end


get '/' do
  redirect '/connect' unless connected?

  # If no start date is set, default to match end date
  # If no date parameters are set, default both to today
  @today = date_today

  from = (params[:from] if not params[:from].empty? rescue nil) || params[:to] || @today
  to = (params[:to] if not params[:to].empty? rescue nil) || @today

  puts from, to, "FT ^"

  @metrics = get_detailed_revenue_metrics(from, to)
  
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
    erb :connect
  end
end

post '/disconnect' do
  API_KEY, API_PWD, SHP_NAME = "", "", ""
  connection_closed
end
