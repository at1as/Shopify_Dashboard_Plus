# Shopify_Dashboard_Plus[![Gem Version](https://badge.fury.io/rb/shopify_dashboard_plus.svg)](http://badge.fury.io/rb/shopify_dashboard_plus)
Pretty Dashboard for Shopify Admin with lots of graphs.

## Screenshots

![screenshot](https://github.com/at1as/at1as.github.io/blob/master/github_repo_assets/dashboard-plus1.jpg)

## Metrics
Choose the interval over which to get data and see it displayed as:

*Currency*
* Currencies Used per Purchase

*Countries*
* Proportion of Sales per Country

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
* To install via the gem: 
  * `gem install shopify_dashboard_plus`
  * Note: Gem build will generally trail the repo by days-to-weeks
* For dependencies see: 
  * `shopify_dashboard_plus.gemfile`
* Retrieve `API Key`, `Password` and `Shop Name` for your store from Shopify Admin
* Run (key, password & name can be passed as environment variables, or later thorugh the UI):
  * `SHP_KEY="my_key" SHP_PWD="my_password" SHP_NAME="my_shop" ./lib/shopify_dashboard_plus.rb`

## TODO

* Regex on front end doesn't work in Safari
* Backend validation of dates
* Not all floats render with a two-digit precision
* Limited to 250 results
