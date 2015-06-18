ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'capybara'
require 'capybara/webkit'
require 'tilt/erb'
require 'vcr'
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

    def setup
      Capybara.current_driver = :webkit
      Capybara.javascript_driver = :webkit
      Capybara.page.driver.browser.ignore_ssl_errors
      Capybara.default_wait_time = 10
      Capybara.always_include_port = true
      Capybara.server_port = 31337
      Capybara.app_host = "http://127.0.0.1"
      Capybara.app = Sinatra::Application
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
      page.driver.block_unknown_urls # JS Graphing Library not needed
      page.visit '/connect'
      invalid_connection(api_key: "bad_api_key!!!1")
      page.visit '/connect'
      invalid_connection(api_pwd: "bad_api_pwd!!!1")
      page.visit '/connect'
      invalid_connection(shop_name: "bad_shop_name!!1")
      page.visit '/connect'
      invalid_connection
    end

  end
end
