# Shopify_Dashboard_Plus [![Build Status](https://travis-ci.org/at1as/Shopify_Dashboard_Plus.svg?branch=master)](https://travis-ci.org/at1as/Shopify_Dashboard_Plus)[![Gem Version](https://badge.fury.io/rb/shopify_dashboard_plus.svg)](http://badge.fury.io/rb/shopify_dashboard_plus)
Pretty Dashboard for Shopify Admin with lots of graphs.

## Screenshots

![screenshot](https://github.com/at1as/at1as.github.io/blob/master/github_repo_assets/dashboard-plus1.jpg)

## Metrics
Choose the interval over which to get data and see it displayed as:

*Sales*
* Daily Sales
* Total Sales
* Average Sales per Day
* Proportion of Sales per Product
* Number of Sales per Product
* Revenue per Product

*Prices*
* Proportion of Items Sold Per Price Point
* Number of Items Sold Per Price Point
* Revenue per Price Point
* Total Savings per Discount Code
* Number of Uses per Discount Code

*Countries*
* Proportion of Sales per Country

*Currency*
* Currencies Used per Purchase

*Customers*
* Purchases per Customer

*Traffic Metrics*
* Referrals per Site
* Referrals per Specific Site Page
* Revenue Per Referral Site
* Revenue Per Specific Referral Site Page

## Usage
* To install manually: 
  * `git clone https://github.com/at1as/Shopify_Dashboard_Plus.git`
* To install using the gem: 
  * `gem install shopify_dashboard_plus`
  * `shopify_dashboard_plus.rb`
* Retrieve `API Key`, `Password` and `Shop Name` for your store from Shopify Admin
* Run (key, password & name can be passed as environment variables, or later thorugh the UI):
  * `SHP_KEY="API KEY" SHP_PWD="PASSWORD" SHP_NAME="SHOP NAME" ./lib/shopify_dashboard_plus.rb`
 
## Notes
* Tested and developed with Ruby 2.0.0, 2.1.2, 2.2.0 on Mac OS 10.10
* Tested against [Learning Photography](http://learning.photography)
* Requires >= Ruby 2.0.0
