module Anonymizer

# Strip discount information and replace with fake data
  def anonymize_discounts(orders)
    discount_code_replacement = Hash.new

    orders.each_with_index do |order, index|
      order['discount_codes'].each_with_index do |dc, inner_index|
        unless dc.nil? or dc.empty?
          old_code = order['discount_codes'][inner_index]['code']

          if not discount_code_replacement[old_code]
            discount_code_replacement[old_code] = Faker::Internet.slug
          end  

          orders[index]['discount_codes'][inner_index]['code'] = discount_code_replacement[old_code]
        end
      end
    end

    orders
  end

  # Strip referral information and replace with fake data
  def anonymize_referrals(orders)
    referring_site_replacement = Hash.new

    orders.each_with_index do |order, index|
      unless order['referring_site'].nil? or order['referring_site'].empty?
        old_site = order['referring_site']

        if not referring_site_replacement[old_site]
          referring_site_replacement[old_site] = Faker::Internet.url
        end

        orders[index]['referring_site'] = referring_site_replacement[old_site]
      end
    end

    orders
  end

  # Strip billing address informatino and replace with fake data
  def anonymize_billing_address(orders)
    billing_address_replacement = Hash.new { |hash, key| hash[key] = {} }

    orders.each_with_index do |order, index|
      unless order['billing_address'].nil? or order['billing_address'].empty?
        old_address = order['billing_address']['address1']

        if billing_address_replacement[old_address].empty?
          billing_address_replacement[old_address]['address1'] = Faker::Address.street_address
          billing_address_replacement[old_address]['address2'] = Faker::Address.secondary_address
          billing_address_replacement[old_address]['city'] = Faker::Address.city
          billing_address_replacement[old_address]['company'] = Faker::Company.name
          billing_address_replacement[old_address]['first_name'] = Faker::Name.first_name
          billing_address_replacement[old_address]['last_name'] = Faker::Name.last_name
          billing_address_replacement[old_address]['latitude'] = Faker::Address.latitude
          billing_address_replacement[old_address]['longitude'] = Faker::Address.longitude
          billing_address_replacement[old_address]['phone'] = Faker::PhoneNumber.phone_number
          billing_address_replacement[old_address]['zip'] = Faker::Address.zip_code
          billing_address_replacement[old_address]['name'] = billing_address_replacement[old_address]['first_name'] + billing_address_replacement[old_address]['last_name']
        end

        orders[index]['billing_address'] = billing_address_replacement[old_address]
      end
    end

    orders
  end

  # Strip line item information and replace with fake data
  def anonymize_line_items(orders)
    line_items_replacement = Hash.new { |hash, key| hash[key] = {} }

    orders.each_with_index do |order, index|
      order['line_items'].each_with_index do |item, inner_index|
        unless item.empty?
          old_item = order['line_items'][inner_index]['product_id']

          if line_items_replacement[old_item].empty?
            line_items_replacement[old_item]['product_id'] = Faker::Number.number(8)
            line_items_replacement[old_item]['title'] = Faker::Commerce.product_name
            line_items_replacement[old_item]['variant_id'] = Faker::Number.number(10)
            line_items_replacement[old_item]['vendor'] = Faker::Commerce.department
            line_items_replacement[old_item]['name'] = Faker::Commerce.product_name
          end

          orders[index]['line_items'][inner_index] = line_items_replacement[old_item]
        end
      end
    end

    orders
  end

  # Strip customer data and replace with fake data
  def anonymize_customers(orders)
    customer_replacement = Hash.new { |hash, key| hash[key] = {} }

    orders.each_with_index do |order, index|
      unless order['customer'].empty?
        old_customer = order['customer']['id']

        if customer_replacement[old_customer].empty?
          customer_replacement[old_customer]['id'] = Faker::Number.number(8)
          customer_replacement[old_customer]['email'] = Faker::Internet.email
          customer_replacement[old_customer]['first_name'] = Faker::Name.first_name
          customer_replacement[old_customer]['last_name'] = Faker::Name.last_name
          # TODO: 
          # Take billing_address parameter to fill in:
          # customer_replacement[customer[:id]][:default_address]
        end
        orders[index]['customer'] = customer_replacement[old_customer]
      end
    end

    orders
  end

end
