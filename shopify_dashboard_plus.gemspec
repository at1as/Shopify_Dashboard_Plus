# coding: utf-8

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

  spec.add_runtime_dependency "sinatra", "~>1.4", ">= 1.4.5"
  spec.add_runtime_dependency "shopify_api", "~>4.0", ">= 4.0.3"
  spec.add_runtime_dependency "chartkick", "~>1.3", ">= 1.3.2"
  spec.add_runtime_dependency "vegas", "~> 0.1", ">= 0.1.11"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "tilt"
  spec.add_development_dependency "rack-test", "~> 0.6", "~> 0.6.3"
end
