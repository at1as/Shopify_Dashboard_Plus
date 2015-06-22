require 'YAML'
require 'json'
require 'ap'
require 'faker'
require_relative 'anonymize_data'


def strip_shop_details(cassette_name: 'authenticate.yml')
	include AnonymizeData

  # Load authentication VCR cassette
  request_data = YAML.load_file "test/fixtures/vcr_cassettes/#{cassette_name}"
  response_payloads = request_data['http_interactions']

  # Iterate through all requests saved in cassette
  # Replace sensitive shop information with randomly generated information
  response_payloads.each_with_index do |payload, index|
    anonymous_shop = AnonymizeData.shop(payload['response']['body']['string'])
    response_payloads[index]['response']['body']['string'] = anonymous_shop
  end

  # Propagate new information to full request payload in YAML file
  request_data['http_interactions'] = response_payloads
  File.open("test/fixtures/vcr_cassettes/#{cassette_name}", 'w') { |f| YAML.dump(request_data, f) }
end


def strip_order_details(cassette_name: nil)
  include AnonymizeData

  # Load orders
  request_data = YAML.load_file "test/fixtures/vcr_cassettes/#{cassette_name}"
  response_payloads = request_data['http_interactions']

  # Iterate through all requests saved in cassette
  # Replace all sensitive order data with randomly generated information
  response_payloads.each_with_index do |payload, index|
    anonymous_order = AnonymizeData.orders(payload['response']['body']['string'])
    response_payloads[index]['response']['body']['string'] = anonymous_order
  end

  # Propagate new information to full request payload in YAML file
  request_data['http_interactions'] = response_payloads
  ap request_data
  #File.open("test/fixtures/vcr_cassettes/#{cassette_name}", 'w') { |f| YAML.dump(request_data, f) }
end


#strip_shop_details(cassette_name: 'authenticate1.yml')
strip_order_details(cassette_name: 'orders_from_2010_01_01_to_2015_01_01-1.yml')
