# Shopify-Dashboard-Plus
Pretty Dashboard for Shopify Admin with lots of graphs.

## Usage
* `git clone https://github.com/at1as/Shopify-Dashboard-Plus.git`
* See `shopify-dashboard-plus.gemfile` for dependencies: shopify_api, sinatra, and chartkick
* Assign RWX permissions on `lib/shopify-dashboard-plus.rb`
* Retrieve `Key, Password and Shop Name for your store from Shopify Admin
* `SHP_KEY="my_key" SHP_PWD="my_password" SHP_NAME="my_shop" ./lib/shopify-dashboard-plus.rb`

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

## Screenshots

* ![screenshot](https://github.com/at1as/at1as.github.io/blob/master/github_repo_assets/dashboard-plus1.jpg)
