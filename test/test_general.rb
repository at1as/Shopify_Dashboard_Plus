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
  
  # Only used for default driver (non-webkit) tests
  def app
    Capybara.app = Sinatra::Application
  end

  # Called before every test_ method
  def setup
    Capybara.current_driver = :webkit
    Capybara.javascript_driver = :webkit
    Capybara.page.driver.browser.ignore_ssl_errors
    Capybara.default_wait_time = 10
    Capybara.always_include_port = true
    Capybara.server_port = 31337
    Capybara.app_host = "http://127.0.0.1"

    # Sporadic race condition in which app gets called before setup completes
    # And then subsequent requests using default driver fail to bind
    # Need to investigate, but for now the next line mitigates it
    app = Capybara.app = Sinatra::Application
  end

  def invalid_connection(api_key: nil, api_pwd: nil, shop_name: nil)
    page.driver.block_unknown_urls #JS Graphing Library not needed
    assert_equal("/connect", page.current_path)
    within '#connect-box' do
      fill_in 'api_key', :with => api_key if api_key
      fill_in 'api_pwd', :with => api_pwd if api_pwd
      fill_in 'shop_name', :with => shop_name if shop_name
      click_button 'connect'
    end
    assert_equal 'Failed to Connect...', find('p#flash').text
  end

  def test_version_exists
    # Should be format 2.1.0. Ensure the 2.1 part converts to an integer
    @version = ShopifyDashboardPlus::VERSION
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

  def test_invalid_credentials
    page.visit '/connect'
    invalid_connection(api_key: "bad api key!!!1")
    page.visit '/connect'
    invalid_connection(api_pwd: "bad api pwd!!!1")
    page.visit '/connect'
    invalid_connection(shop_name: "bad shop name!!1")
    page.visit '/connect'
    invalid_connection
  end

  def test_launch_sinatra
    # Script returns true for zero exit status, false for non-zero
    assert true, `ruby "./bin/shopify_dashboard_plus.rb"`
  end

end

