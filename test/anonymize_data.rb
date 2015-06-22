module AnonymizeData
  Faker::Config.locale = :"en-CA"

  # Intercept Shopify Orders and replace data with generated mock data
  # Ensure predictable replacements of data 
  # e.g. If a real order from John Galt is replaced with a fake name, Jane Smith, 
  # every instance of John Galt should be replaced with the same data. 
  # Same applies to order items, prices, etc
	def AnonymizeData.orders(raw_order_data)

    begin
      order_data = JSON.parse(raw_order_data).fetch('orders')
    rescue
      return raw_order_data
      #return nil
    end

    # Map new order information to the old keys, so that the same replacement data can be
    # substituted for every instance of the same original value
    # This will preserve toe continuity for repeat customers, etc
    discount_code_replacement = Hash.new
    referring_site_replacement = Hash.new
    billing_address_replacement = Hash.new { |hash, key| hash[key] = {} }
    customer_replacement = Hash.new { |hash, key| hash[key] = {} }
    line_items_replacement = Hash.new { |hash, key| hash[key] = {} }


    order_data.each_with_index do |order, index|

      ## Referring Site
      unless order['referring_site'].nil? or order['referring_site'].empty?
        old_site = order['referring_site']

        if referring_site_replacement[old_site]
          order_data[index]['referring_site'] = referring_site_replacement[old_site]
        else
          referring_site_replacement[old_site] = Faker::Internet.url
          order_data[index]['referring_site'] = referring_site_replacement[old_site]
        end
      end


      ## Discounts
      order['discount_codes'].each_with_index do |dc, inner_index|
        unless dc.nil? or dc.empty?
          old_code = order['discount_codes'][inner_index]['code']

          if discount_code_replacement[old_code]
            order_data[index]['discount_codes'][inner_index]['code'] = discount_code_replacement[old_code]
          else
            discount_code_replacement[old_code] = Faker::Internet.slug
            order_data[index]['discount_codes'][inner_index]['code'] = discount_code_replacement[old_code]
          end
        end
      end


      ## Billing Address
      unless order['billing_address'].nil? or order['billing_address'].empty?
        old_address = order['billing_address']['address1']

        if not billing_address_replacement[old_address].empty?
          order_data[index]['billing_address'] = billing_address_replacement[old_address]
        else
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
          order_data[index]['billing_address'] = billing_address_replacement[old_address]
        end
      end


      ## Line Items
      order['line_items'].each_with_index do |item, inner_index|
        unless item.empty?
          old_item = order['line_items'][inner_index]['product_id']

          if not line_items_replacement[old_item].empty?
            order_data[index]['line_items'][inner_index] = line_items_replacement[old_item]
          else
            line_items_replacement[old_item]['product_id'] = Faker::Number.number(8)
            line_items_replacement[old_item]['title'] = Faker::Commerce.product_name
            line_items_replacement[old_item]['variant_id'] = Faker::Number.number(10)
            line_items_replacement[old_item]['vendor'] = Faker::Commerce.department
            line_items_replacement[old_item]['name'] = Faker::Commerce.product_name
            order_data[index]['line_items'][inner_index] = line_items_replacement[old_item]
          end
        end
      end


      ## Customer
      unless order['customer'].empty?
        old_customer = order['customer']['id']

        if not customer_replacement[old_customer].empty?
          order_data[index]['customer'] = customer_replacement[old_customer]
        else
          customer_replacement[old_customer]['id'] = Faker::Number.number(8)
          customer_replacement[old_customer]['email'] = Faker::Internet.email
          customer_replacement[old_customer]['first_name'] = Faker::Name.first_name
          customer_replacement[old_customer]['last_name'] = Faker::Name.last_name
          # TODO:
          # customer_replacement[customer[:id]][:default_address]
          order_data[index]['customer'] = customer_replacement[old_customer]
        end 
      end
    end

    order_data
	end


  # Replace the shop data from real stores with randomly generated data
  def AnonymizeData.shop(raw_store_data)
    begin
      store_data = JSON.parse(raw_store_data).fetch('shop')
    rescue
      return raw_store_data
    end

    # Store Details
    store_data['id'] = Faker::Number.number(8) if store_data['id']
    store_data['name'] = Faker::Company.name if store_data['name']
    store_data['domain'] = Faker::Internet.url if store_data['domain']
    
    # Owner
    store_data['shop_owner'] = Faker::Name.name if store_data['shop_owner']
    store_data['phone'] = Faker::PhoneNumber.phone_number if store_data['phone']
    store_data['email'] = Faker::Internet.email if store_data['email']
    store_data['customer_email'] = Faker::Internet.email if store_data['customer_email']
    
    # Address
    store_data['city'] = Faker::Address.city if store_data['city']
    store_data['address1'] = Faker::Address.street_address if store_data['address1']
    store_data['longitude'] = Faker::Address.longitude if store_data['longitude']
    store_data['latitude'] = Faker::Address.latitude if store_data['latitude']
    store_data['zip'] = Faker::Address.zip if store_data['zip']

    store_data.to_json
  end


end
