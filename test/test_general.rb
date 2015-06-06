ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'capybara'
require 'capybara/webkit'
require 'tilt/erb'
require './lib/shopify_dashboard_plus.rb'
require './lib/shopify_dashboard_plus/version'
require './lib/shopify_dashboard_plus/helpers'
require './lib/shopify_dashboard_plus/report'


class TestShopifyDashboardPlus < MiniTest::Test
  include Rack::Test::Methods
  include Capybara::DSL
  
  def app
    Capybara.app = Sinatra::Application
  end
  
  def setup
    Capybara.current_driver = :webkit
    @version = ShopifyDashboardPlus::VERSION
  end

  def connection(api_key: nil, api_pwd: nil, shop_name: nil)
    visit '/'
    fill_in 'api_key', :with => api_key if api_key
    fill_in 'api_pwd', :with => api_pwd if api_pwd
    fill_in 'shop_name', :with => shop_name if shop_name
    click_button 'connect'
  end

  def test_version_exists
    # Should be format 2.1.0. Ensure the 2.1 part converts to an integer
    assert @version.gsub(/.\d\Z/, "").to_i, "#{@version} does not seem to be formated as X.Y.Z where X, Y, Z are integers"
  end

  def test_directories_exist
    assert_equal(true, File.directory?("./bin"), "tmp directory does not exist!")
    assert_equal(true, File.directory?("./lib"), "tmp directory does not exist!")
    assert_equal(true, File.directory?("./public"), "tmp directory does not exist!")
    assert_equal(true, File.directory?("./views"), "tmp directory does not exist!")
  end

  def test_no_connection_redirect
    get '/?from=2013-01-01&to=2015-01-01'
    assert last_response.redirect?
    follow_redirect!
    assert_equal(last_request.fullpath, "/connect")
  end

  def test_bad_api_credentials
    page.driver.block_unknown_urls #JS Graphing Library not needed
    connection( api_key: "bad api key!!1" )
    assert_equal 'Failed to Connect...', find('p#flash').text
    connection( api_pwd: "bad api pwd!!1" )
    assert_equal 'Failed to Connect...', find('p#flash').text
    connection( shop_name: "bad shop name!!1" )
    assert_equal 'Failed to Connect...', find('p#flash').text
    connection()
    assert_equal 'Failed to Connect...', find('p#flash').text
  end
  
  def test_launch_sinatra
    # Script returns true for zero exit status, false for non-zero
    assert true, `ruby "./bin/shopify_dashboard_plus.rb"`
  end

end

