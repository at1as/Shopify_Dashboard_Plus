# Shopify_Dashboard_Plus [![Gem Version](https://badge.fury.io/rb/shopify_dashboard_plus.svg)](http://badge.fury.io/rb/shopify_dashboard_plus) [![Build Status](https://travis-ci.org/at1as/Shopify_Dashboard_Plus.svg?branch=master)](https://travis-ci.org/at1as/Shopify_Dashboard_Plus) <a href="https://codeclimate.com/github/at1as/Shopify_Dashboard_Plus"><img src="https://codeclimate.com/github/at1as/Shopify_Dashboard_Plus/badges/gpa.svg" /></a>
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

## Installation
* To install manually: 
  * `git clone https://github.com/at1as/Shopify_Dashboard_Plus.git`
* To install using the gem: 
  * `gem install shopify_dashboard_plus`
* Or, if you just want to try it out, head over to [Heroku](https://shopifydashboardplus.herokuapp.com/)
  * Generally it's unwise to pass your API key & password through some hosted website. The code run on Heroku is taken automatically from this repo and you can check the source to see that the keys aren't being saved, but if you're in doubt, either create new credentials for this app and then revoke them after you're finished, or just install run locally with either option listed above instead.

## Usage
* Retrieve `API Key`, `Password` and `Shop Name` for your store from Shopify Admin
* Run with environment variables
  * `SHP_KEY="API KEY" SHP_PWD="PASSWORD" SHP_NAME="SHOP NAME" ./lib/shopify_dashboard_plus.rb` [manual installation]
  * `SHP_KEY="API KEY" SHP_PWD="PASSWORD" SHP_NAME="SHOP NAME" shopify_dashboard_plus.rb` [Gem]
* Run without environment variables (and pass these later thorugh the UI)
  * `./lib/shopify_dashboard_plus.rb`
  * `shopify_dashboard_plus.rb`
 
## Notes
* Tested with:
  * Ruby 2.0.0, 2.1.2, 2.2.0 on Mac OS 10.10 (Locally)
  * Ruby 2.0.0, 2.1.3, 2.2.0 on Ubuntu Linux 12.04 (TravisCI)
* Requires >= Ruby 2.0.0
* Tested against [Learning Photography](http://learning.photography)
