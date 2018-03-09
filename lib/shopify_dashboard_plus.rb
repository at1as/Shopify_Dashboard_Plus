#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'tilt/erb'
require 'shopify_api'
require 'uri'
require 'chartkick'
require_relative 'shopify_dashboard_plus/currency'
require_relative 'shopify_dashboard_plus/helpers'
require_relative 'shopify_dashboard_plus/discount_report'
require_relative 'shopify_dashboard_plus/revenue_report'
require_relative 'shopify_dashboard_plus/sales_report'
require_relative 'shopify_dashboard_plus/traffic_report'
require_relative 'shopify_dashboard_plus/version'


HELP = <<-USAGE
Set global variables through the WebUI or call with the correct ENV variables:

  Example:

    SHP_KEY="<shop_key>" SHP_PWD="<shop_password>" SHP_NAME="<shop_name>" ./lib/shopify-dashboard.rb
USAGE


configure do
  enable :sessions
  
  set :public_dir, Proc.new { File.join(root, "../public") }
  set :views, Proc.new { File.join(root, "../views") }
  
  $connected ||= false
  $flash     ||= nil

  # If Environment variables were set, connect to Shopify Admin immediately
  # Refuse to start server if variables are passed but incorrect
  if ENV["SHP_KEY"] && ENV["SHP_PWD"] && ENV["SHP_NAME"]
    API_KEY   = ENV["SHP_KEY"]
    PASSWORD  = ENV["SHP_PWD"]
    SHOP_NAME = ENV["SHP_NAME"]
    
    begin
      ShopifyAPI::Base.site = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com/admin"
      shop = ShopifyAPI::Shop.current
      
      $shop_name = SHOP_NAME
      $currency  = shop.money_with_currency_format
      $connected = true
    rescue URI::InvalidURIError, ActiveResource::ResourceNotFound => e
      puts "\nFailed to connect using provided credentials for API KEY #{API_KEY} : #{e})\n #{HELP}"
      exit
    end
  end
end

helpers ApplicationHelpers


before do
  $flash   = ''
  @metrics = false
end


get '/' do
  redirect '/connect' unless connected? && authenticated?

  # If no start date is set, default to match end date
  # If no date parameters are set, default both to today
  @today = date_today
  from   = (params[:from] unless params[:from].empty? rescue nil) || (params[:to] unless params[:to].empty? rescue nil) || @today
  to     = (params[:to] unless params[:to].empty? rescue nil) || @today

  to = @today if to > @today

  if date_range_valid?(from, to)
    @metrics = get_detailed_revenue_metrics(from, to)
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
  API_KEY  = ''
  API_PWD  = ''
  SHP_NAME = ''
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

