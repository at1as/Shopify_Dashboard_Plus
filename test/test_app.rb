# frozen_string_literal: true

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'tilt/erb'
require 'vcr'
require 'webmock'
require './lib/shopify_dashboard_plus.rb'
require './lib/shopify_dashboard_plus/version'
require './lib/shopify_dashboard_plus/helpers'
require './lib/shopify_dashboard_plus/discount_report'
require './lib/shopify_dashboard_plus/revenue_report'
require './lib/shopify_dashboard_plus/sales_report'
require './lib/shopify_dashboard_plus/traffic_report'

ENV['RACK_ENV'] = 'test'

## Application tests related to:
##   Launching application, File Structure, and Version


class TestShopifyDashboardPlus < MiniTest::Test
  include Rack::Test::Methods

  # VCR from test_mockdata test suite should not intercept these HTTP requests
  VCR.turned_off do

    # Allow real HTTP Requests
    WebMock.allow_net_connect!

    def app
      Capybara.app = Sinatra::Application
    end

    def test_version_exists
      # Should be formatted as A.B.C (A, B, C all integers) Ex. => 2.1.3
      # Ensure the portion before the last decimal converts to an integer (A.B). Ex => 2.1.to_i
      @version = ShopifyDashboardPlus::VERSION
      assert @version.gsub(/.\d\Z/, "").to_i, "#{@version} does not seem to be formated as X.Y.Z where X, Y, Z are integers"
    end

    def test_directories_exist
      assert_equal(true, File.directory?("./bin"), "bin directory does not exist!")
      assert_equal(true, File.directory?("./lib"), "lib directory does not exist!")
      assert_equal(true, File.directory?("./lib/shopify_dashboard_plus"), "lib/shopify_dashboard_plus directory does not exist!")
      assert_equal(true, File.directory?("./public"), "public directory does not exist!")
      assert_equal(true, File.directory?("./public/css"), "public/css directory does not exist!")
      assert_equal(true, File.directory?("./public/js"), "public/js directory does not exist!")
      assert_equal(true, File.directory?("./test"), "test directory does not exist!")
      assert_equal(true, File.directory?("./test/fixtures"), "test/fixtures directory does not exist!")
      assert_equal(true, File.directory?("./views"), "views directory does not exist!")
    end

    def test_launch_sinatra
      # Script returns true for zero exit status, false for non-zero
      assert true, `ruby "./bin/shopify_dashboard_plus.rb"`
    end

  end
end
