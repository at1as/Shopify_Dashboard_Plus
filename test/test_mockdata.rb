# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'tilt/erb'
require 'capybara'
require 'vcr'
require 'byebug'
require './lib/shopify_dashboard_plus.rb'
require './lib/shopify_dashboard_plus/version'
require './lib/shopify_dashboard_plus/helpers'
require './lib/shopify_dashboard_plus/discount_report'
require './lib/shopify_dashboard_plus/revenue_report'
require './lib/shopify_dashboard_plus/sales_report'
require './lib/shopify_dashboard_plus/traffic_report'

ENV['RACK_ENV'] = 'test'

VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr_cassettes'

  # Shopify Gem uses Net::HTTP
  # Requests can be captured using webmock
  config.hook_into :webmock
  config.ignore_hosts '127.0.0.1', 'localhost', '0.0.0.0', 'example.com'
  # config.debug_logger = File.open('request_log.log', 'w')

  # Allow other test suites to send real HTTP requests
  config.allow_http_connections_when_no_cassette = true

  # Show response payload in body as plaintext and hide API credentials
  config.before_record { |cassette| cassette.response.body.force_encoding('UTF-8') }
  config.filter_sensitive_data('<API_KEY>')   { ENV['API_KEY']   || "testkey"  }
  config.filter_sensitive_data('<API_PWD>')   { ENV['API_PWD']   || "testpwd"  }
  config.filter_sensitive_data('<SHOP_NAME>') { ENV['SHOP_NAME'] || "testshop" }

  # Match certain requests by date in the payload
  config.register_request_matcher :port do |req1, req2|
    @today == VCR::HTTPInteraction
  end
end


class TestShopifyDashboardPlus < MiniTest::Test
  include Rack::Test::Methods

  attr_accessor :authenticated

  def app
    Sinatra::Application
  end

  def setup
    @today = DateTime.now.strftime('%Y-%m-%d')
    @hardcoded_day = "2015-06-26"
  end


  #######################
  ## Common Methods
  #######################

  def env_set?
    true if ENV['API_KEY'] && ENV['API_PWD'] && ENV['SHOP_NAME']
  end

  def authenticate
    return if authenticated
    
    VCR.use_cassette('authenticate', :match_requests_on => [:path]) do

      # Use environment variables if specified, otherwise use fake information
      # Shopify URL will appear as <api_key>:<api_pwd>@<storename>.myshopify.com/<path>
      # VCR casettes should match on the URI path, not the host information
      payload = if env_set?
                  "api_key=#{ENV['API_KEY']}&api_pwd=#{ENV['API_PWD']}&shop_name=#{ENV['SHOP_NAME']}"
                else
                  "api_key=testkey&api_pwd=testpwd&shop_name=testshop"
                end
      
      post('/connect', payload, "Content-Type" => "application/x-www-form-urlencoded")
    end
  end

  def build_url(from: nil, to: nil)
    if from && to
      "/?from=#{from}&to=#{to}"
    elsif from
      "/?from=#{from}"
    elsif to
      "/?to=#{to}"
    else
      "/"
    end
  end

  def validate_body(returned_body)
    # No Three digit precision decimal points
    assert_equal 0, returned_body.scan(/[0-9]{1,}[.][0-9]{3,}/).length

    # Time / Times is pluralized correctly
    assert_equal 0, returned_body.scan(/1 Times/).length
    assert_equal 0, returned_body.scan(/[02-9] Time^[s]/).length

    # Referral / Referrals is pluralized correctly
    assert_equal 0, returned_body.scan(/1 Referrals/).length
    assert_equal 0, returned_body.scan(/[02-9] Referral^[s]/).length

    # Valid Response
    assert_match(/Retrieve metrics over the following period/, returned_body)
    assert_equal 0, returned_body.scan(/Invalid Dates. Please use format YYYY-MM-DD/).length
  end


  #######################
  ## Test Cases
  #######################

  def test_unauthorized_redirect
    VCR.turned_off do
      get '/?from=2013-01-01&to=2015-01-01'
      follow_redirect!
      assert_match(/connect/, last_request.fullpath)
    end
  end

  def test_no_parameters
    # Validate results with no start date or end date parameter set
    # Results should default to today's results
    return unless env_set?
    
    authenticate
    url = build_url
    
    # Will reuse cassette for tests run the same day (in which the URL paramater created_at_min=YYYY-MM-DD will be identical)
    # Will append a new entry on a new day
    VCR.use_cassette(:orders_no_paramaters, :erb => { :today => @today }, :record => :once, :match_requests_on => [:method]) do
      r = get url
      assert_equal last_request.fullpath, '/'

      # Ensure default start and end date are today's date
      assert_equal 2, r.body.scan(/placeholder=\"#{@today}\"/).length
      validate_body(r.body)
    end
  end


  def test_only_start_date_parameter
    # Validate results with only start date parameter set
    # End date should default to today
    authenticate
    url = build_url(:from => "2010-01-01")

    VCR.use_cassette(:orders_from_2010_01_01, :record => :once, :match_requests_on => [:path]) do
      r = get url
      assert_equal '/?from=2010-01-01', last_request.fullpath
      validate_body(r.body)
    end
  end


  def test_only_end_date_parameter
    # Validate results with only the end date parameter set
    authenticate
    url = build_url(:to => @hardcoded_day)

    VCR.use_cassette("orders_to_#{@hardcoded_day}", :match_requests_on => [:path]) do
      r = get url
      assert_equal "/?to=#{@hardcoded_day}", last_request.fullpath
      validate_body(r.body)
    end
  end


  def test_valid_date_range
    # Validate results over a valid start date and end date
    authenticate
    url = build_url(:from => "2010-01-01", :to => "2015-01-01")

    VCR.use_cassette(:orders_from_2010_01_01_to_2015_01_01, :match_requests_on => [:path]) do
      r = get url

      assert_equal '/?from=2010-01-01&to=2015-01-01', last_request.fullpath
      validate_body(r.body)
    end
  end


  def test_pagination
    # Validate that more than 250 results can be returned (the limit)
    authenticate
    url = build_url(:from => "2010-01-01", :to => "2015-01-01")
    
    VCR.use_cassette(:multiple_pages_orders, :match_requests_on => [:path]) do
      r = get url

      sales_regexp = r.body.scan(/(Number of Sales[<][\/]h5>)\n(.*[<]h3[ ]class=["]money["][>][0-9]*)/).first[1]
      number_of_sales = sales_regexp.scan(/\d+$/).first

      assert number_of_sales.to_i > 250, "number of sales (#{number_of_sales}) does not encompass at least two pages (> 250 entries)"
    end
  end


  def test_empty_order_set
    # Validate an empty order is rendered correctly
    authenticate
    url = build_url

    VCR.use_cassette(:orders_none, :match_requests_on => [:path]) do
      r = get url

      validate_body(r.body)
    end
  end


  #######################
  # Negative Test Cases
  #######################

  def test_end_date_before_start_date
    authenticate
    url = build_url(:from => "2015-01-01", :to => "2010-01-01")

    get url
    assert_match(/Invalid Dates. Please use format YYYY-MM-DD/, last_response.body)
  end

  def test_unsupported_date_characters
    authenticate
    url = build_url(:from => "abcd", :to => "fghijk")

    get url
    assert_match(/Invalid Dates. Please use format YYYY-MM-DD/, last_response.body)
  end
end
