ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'capybara'
require 'capybara/webkit'
require 'tilt/erb'
require 'vcr'
require 'webmock'
require './lib/shopify_dashboard_plus.rb'
require './lib/shopify_dashboard_plus/version'
require './lib/shopify_dashboard_plus/helpers'
require './lib/shopify_dashboard_plus/report'


## Application tests related to:
##   Front-end testing (flash errors messages, etc) using Capybara-Webkit


class TestShopifyDashboardPlus < MiniTest::Test
  include Rack::Test::Methods
  include Capybara::DSL

  # VCR from test_mockdata test suite should not intercept these HTTP requests
  VCR.turned_off do

    # Allow real HTTP Requests
    WebMock.allow_net_connect!
    
    # Necessary to use capybara with sinatra applicaiton
    Capybara.app = Sinatra::Application


    def setup
      Capybara.configure do |config|
        config.run_server = false
        config.current_driver = :webkit
        config.default_driver = :webkit
        config.javascript_driver = :webkit
        config.page.driver.browser.ignore_ssl_errors
        config.default_wait_time = 10
        config.always_include_port = true
        config.server_port = 31337
        config.app_host = "http://127.0.0.1"
      end
    end

    def invalid_connection(api_key: nil, api_pwd: nil, shop_name: nil)
      assert_equal("/connect", page.current_path)
      within '#connect-box' do
        fill_in 'api_key', :with => api_key if api_key
        fill_in 'api_pwd', :with => api_pwd if api_pwd
        fill_in 'shop_name', :with => shop_name if shop_name
        click_button 'connect'
      end
      assert_equal 'Failed to Connect...', find('p#flash').text
    end

    def test_invalid_credentials_flash_message
      page.visit '/connect'
      invalid_connection(api_key: "bad_api_key")
      page.visit '/connect'
      invalid_connection(api_pwd: "bad_api_pwd")
      page.visit '/connect'
      invalid_connection(shop_name: "bad_shop_name")
      page.visit '/connect'
      invalid_connection
    end

  end
end
