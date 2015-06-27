#!/usr/bin/env ruby

require 'sinatra'
require 'tilt/erb'
require 'shopify_api'
require 'uri'
require 'chartkick'
require_relative 'shopify_dashboard_plus/helpers'
require_relative 'shopify_dashboard_plus/report'
require_relative 'shopify_dashboard_plus/version'

configure do
  enable :sessions
  
  set :public_dir, "#{__dir__}/../public"
  set :views, "#{__dir__}/../views"

  $connected ||= false
  $metrics ||= false
  $flash ||= nil

  HELP = <<-END
  Set global variables through the WebUI or call with the correct ENV variables:
    Example: SHP_KEY=\"<shop_key>\" SHP_PWD=\"<shop_password>\" SHP_NAME=\"<shop_name>\" ./lib/shopify-dashboard.rb
  END

  # If Environment variables were set connect to Shopify Admin immediately
  # Refuse to start server if variables are passed but incorrect
  if ENV["SHP_KEY"] && ENV["SHP_PWD"] && ENV["SHP_NAME"]
    API_KEY = ENV["SHP_KEY"]
    PASSWORD = ENV["SHP_PWD"]
    SHOP_NAME = ENV["SHP_NAME"]
    
    begin
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      shop = ShopifyAPI::Shop.current
      $shop_name = SHOP_NAME
      $currency = shop.money_with_currency_format
      $connected = true
      session[:logged_in] = true
    rescue Exception => e
      puts "\nFailed to connect using provided credentials...(Exception: #{e})\n #{HELP}"
      exit
    end
  end

  
  # When adding 44.95.round(2) + 940.6.round(2) the precision of the result will be 985.5500000000001
  # In a sample of 100_000_000_000 entries, the precision will round up cents
  # Since all numbers are currency, the plus method will trim to two decimals
  # Numbers returned as: 44, 44.5, or 44.51
  class Fixnum
    def plus(amount)
      result = self + (amount.to_f rescue 0)
      result.round(2)
    end
  end

  class Float
    def plus(amount)
      result = self + (amount.to_f rescue 0)
      result.round(2)
    end
  end

  # For < Ruby 2.1 Compatability
  class Array
    def to_h
      Hash[*self.flatten]
    end
  end
end

helpers ApplicationHelpers


before do
  $flash = nil
  $metrics = false
end


get '/' do
  redirect '/connect' unless connected? and authenticated?

  # If no start date is set, default to match end date
  # If no date parameters are set, default both to today
  @today = date_today
  from = (params[:from] if not params[:from].empty? rescue nil) || (params[:to] if not params[:to].empty? rescue nil) || @today
  to = (params[:to] if not params[:to].empty? rescue nil) || @today

  to = @today if to > @today

  if date_range_valid?(from, to)
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
