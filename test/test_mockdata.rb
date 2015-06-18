ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'tilt/erb'
require 'capybara'
require 'vcr'
require 'byebug'
require './lib/shopify_dashboard_plus.rb'
require './lib/shopify_dashboard_plus/version'
require './lib/shopify_dashboard_plus/helpers'
require './lib/shopify_dashboard_plus/report'


VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr_cassettes'

  # Shopify Gem uses Net::HTTP
  # Requests can be captured using webmock
  config.hook_into :webmock
  config.ignore_hosts '127.0.0.1', 'localhost', '0.0.0.0'
end


class TestShopifyDashboardPlus < MiniTest::Test
  include Rack::Test::Methods

  attr_accessor :authenticated

  def app
    Capybara.app = Sinatra::Application
  end

  def authenticate
    unless authenticated
      VCR.use_cassette('authenticate') do
        payload = "api_key=#{ENV['API_KEY']}&api_pwd=#{ENV['API_PWD']}&shop_name=#{ENV['SHOP_NAME']}"
        post('/connect', payload, {"Content-Type" => "application/x-www-form-urlencoded"})
      end
      authenticated = true
    end
  end

  def build_url(from: nil, to: nil)
    if from and to
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
    assert_match /Retrieve metrics over the following period/, returned_body
    assert_equal 0, returned_body.scan(/Invalid Dates. Please use format YYYY-MM-DD/).length
  end


  def test_unauthorized_redirect
    VCR.turned_off do
      get '/?from=2013-01-01&to=2015-01-01'
      follow_redirect!
      assert_match /connect/, last_request.fullpath
    end
  end

  def test_no_parameters
    authenticate
    url = build_url
    
    VCR.use_cassette(:orders_no_paramaters) do
      r = get url

      assert_equal last_request.fullpath, '/'
      validate_body(r.body)
    end
  end

  def test_valid_date_range
    authenticate
    url = build_url(:from => "2010-01-01", :to => "2015-01-01")

    VCR.use_cassette(:orders_2010_01_01_to_2015_01_01) do
      r = get url
      
      assert_equal '/?from=2010-01-01&to=2015-01-01', last_request.fullpath
      validate_body(r.body)
    end
  end

  def test_end_date_before_start_date
    authenticate
    url = build_url(:from => "2015-01-01", :to => "2010-01-01")

    get url
    assert_match /Invalid Dates. Please use format YYYY-MM-DD/, last_response.body
  end

  def test_unsupported_date_characters
    authenticate
    url = build_url(:from => "abcd", :to => "fghijk")

    get url
    assert_match /Invalid Dates. Please use format YYYY-MM-DD/, last_response.body
  end


  # Validate that more than 250 results can be returned (the limit)
  

end
