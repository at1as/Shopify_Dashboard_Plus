# frozen_string_literal: true

require_relative 'currency'
require_relative 'helpers'
require_relative 'report'

module ShopifyDashboardPlus
  class TrafficReport < Report
    using Currency

    def number_of_referrals
      referring_sites = Hash.new(0)
      referring_pages = Hash.new(0)

      @orders.each do |order|
        if order.attributes['referring_site'].empty?
          referring_pages['None'] += 1
          referring_sites['None'] += 1
        else
          host = get_host(order.referring_site)
          page = strip_protocol(order.referring_site)
          referring_pages[page] += 1
          referring_sites[host] += 1
        end
      end
      
      {
        :referral_sites    => referring_sites.sort.to_h,
        :top_referral_site => max_hash_key_exclude_value(referring_sites, 'none'),
        :referral_pages    => referring_pages.sort.to_h,
        :top_referral_page => max_hash_key_exclude_value(referring_pages, 'none')
      }
    end

    def traffic_revenue
      revenue_per_referral_page = Hash.new(0.0)
      revenue_per_referral_site = Hash.new(0.0)

      @orders.each do |order|
        order.line_items.each do |item|
          if order.attributes['referring_site'].empty?
            revenue_per_referral_page['None'] = revenue_per_referral_page['None'].plus(item.price)
            revenue_per_referral_site['None'] = revenue_per_referral_site['None'].plus(item.price)
          else
            host = get_host(order.referring_site)
            page = strip_protocol(order.referring_site)
            revenue_per_referral_site[host] = revenue_per_referral_site[host].plus(item.price)
            revenue_per_referral_page[page] = revenue_per_referral_page[page].plus(item.price)
          end
        end
      end
      
      {
        :revenue_per_referral_site => revenue_per_referral_site.sort.to_h,
        :top_referral_site_revenue => max_hash_key_exclude_value(revenue_per_referral_site, 'none'),
        :revenue_per_referral_page => revenue_per_referral_page.sort.to_h,
        :top_referral_page_revenue => max_hash_key_exclude_value(revenue_per_referral_page, 'none')
      }
    end

    def to_h
      traffic_revenue.merge(number_of_referrals)
    end
  end
end
