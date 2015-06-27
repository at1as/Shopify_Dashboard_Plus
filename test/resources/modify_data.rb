module ModifyData

  Faker::Config.locale = :"en-CA"
  

  # Replace the shop data from real stores with randomly generated data
  def ModifyData.anonymize_shop(raw_store_data)

    store_data = JSON.parse(raw_store_data).fetch('shop') rescue (return raw_store_data)
    
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

    # Set data back under the json 'shop' key and return as JSON
    updated_store_data = JSON.parse('{}')
    updated_store_data['shop'] = store_data
    updated_store_data.to_json
  end


  # Intercept Shopify Orders and replace data with generated mock data
  # Ensure predictable replacements of data
  # e.g. If a real order from John Galt is replaced with a fake name, Jane Smith, 
  # every instance of John Galt should be replaced with the same data. 
  def ModifyData.anonymize_orders(raw_order_data)
    
    order_data = JSON.parse(raw_order_data).fetch('orders') rescue (return raw_order_data)

    order_data = anonymize_discounts(order_data)
    order_data = anonymize_referrals(order_data)
    order_data = anonymize_billing_address(order_data)
    order_data = anonymize_line_items(order_data)
    order_data = anonymize_customers(order_data)

    # Set data back under the json 'orders' key and return as JSON
    updated_order_data = JSON.parse('{}')
    updated_order_data['orders'] = order_data
    updated_order_data.to_json
  end


  # Traverse through orders and return a new array with each order <multiplier_constant> times
  def ModifyData.duplicate_orders(raw_order_data, multiplier_constant:)
    order_data = JSON.parse(raw_order_data).fetch('orders') rescue (return raw_order_data)
    duplicated_order_data = []

    order_data.each do |order|
      multiplier_constant.to_i.times { duplicated_order_data << order }
    end

    # Set data back under the json 'orders' key and return as JSON
    returned_order_data = JSON.parse('{}')
    returned_order_data['orders'] = duplicated_order_data
    returned_order_data.to_json
  end


  # Ensure at least <floor> orders exist, or otherwise continually append the last order until enough orders exist
  def ModifyData.number_of_orders_floor(raw_order_data, floor:)
    order_data = JSON.parse(raw_order_data).fetch('orders') rescue (return raw_order_data)

    order_delta = order_data.length - floor

    if order_delta >= 0
      return raw_order_data
    else
      order_delta.to_i.times { new_order_data << order_data.last }
    end

    # Set data back under the json 'orders' key and return as JSON
    returned_order_data = JSON.parse('{}')
    returned_order_data['orders'] = new_order_data
    returned_order_data.to_json
  end


  # Ensure no more than <ceiling> orders exist, or otherwise clip the array at <ceiling>
  def ModifyData.number_of_orders_ceiling(raw_order_data, ceiling:)
    order_data = JSON.parse(raw_order_data).fetch('orders') rescue (return raw_order_data)
    trimmed_order_data = []

    order_delta = ceiling - order_data.length

    if order_delta >= 0
      return raw_order_data
    else
      ceiling.to_i.times { |i| trimmed_order_data << order_data[i] }
    end

    # Set data back under the json 'orders' key and return as JSON
    returned_order_data = JSON.parse('{}')
    returned_order_data['orders'] = trimmed_order_data
    returned_order_data.to_json
  end

end
