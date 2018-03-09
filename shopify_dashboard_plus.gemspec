# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'
require 'shopify_dashboard_plus/version'

Gem::Specification.new do |spec|
  spec.name          = "shopify_dashboard_plus"
  spec.date          = Date.today.to_s
  spec.version       = ShopifyDashboardPlus::VERSION
  spec.authors       = ["Jason Willems"]
  spec.email         = ["jason@willems.ca"]
  spec.summary       = "Extended dashboard for shopify admin"
  spec.description   = "Dashboard for Shopify Admin with lots of graphs and other metrics"
  spec.homepage      = "https://github.com/at1as/shopify-dashboard-plus"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "chartkick", "~>2.3"
  spec.add_runtime_dependency "shopify_api", "4.9.1"
  spec.add_runtime_dependency "sinatra", "~>2.0.1"
  spec.add_runtime_dependency "vegas", "~> 0.1", ">= 0.1.11"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "capybara", "~> 2.18.0"
  spec.add_development_dependency "capybara-webkit", "~> 1.15"
  spec.add_development_dependency "minitest", "~> 5.11"
  spec.add_development_dependency "faker", "~>1.8"
  spec.add_development_dependency "rack-test", "~> 0.8"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rubocop", "~> 0.53.0"
  spec.add_development_dependency "tilt", '~> 2.0'
  spec.add_development_dependency "vcr", "~>3.0"
  spec.add_development_dependency "webmock", "~>3.3"
end

