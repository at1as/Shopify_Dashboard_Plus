require 'YAML'
require 'json'
require 'faker'
require_relative 'resources/modify_data'
require_relative 'resources/anonymizer'


def strip_shop_details(cassette_name:)
	include ModifyData
  include Anonymizer

  # Load shop details authentication VCR cassette
  request_data = YAML.load_file "test/fixtures/vcr_cassettes/#{cassette_name}"
  response_payloads = request_data['http_interactions']

  # Iterate through all requests saved in cassette
  # Replace sensitive shop information with randomly generated information
  response_payloads.each_with_index do |payload, index|
    anonymous_shop = ModifyData.anonymize_shop(payload['response']['body']['string'])
    response_payloads[index]['response']['body']['string'] = anonymous_shop
  end

  # Propagate new information to full request payload in YAML file
  request_data['http_interactions'] = response_payloads
  File.open("test/fixtures/vcr_cassettes/#{cassette_name}", 'w') { |f| YAML.dump(request_data, f) }
end


def strip_order_details(cassette_name:)
  include ModifyData
  include Anonymizer

  # Load orders
  request_data = YAML.load_file "test/fixtures/vcr_cassettes/#{cassette_name}"
  response_payloads = request_data['http_interactions']

  # Iterate through all requests saved in cassette
  # Replace all sensitive order data with randomly generated information
  response_payloads.each_with_index do |payload, index|
    anonymous_order = ModifyData.anonymize_orders(payload['response']['body']['string'])
    response_payloads[index]['response']['body']['string'] = anonymous_order
  end

  # Propagate new information to full request payload in YAML file
  request_data['http_interactions'] = response_payloads
  File.open("test/fixtures/vcr_cassettes/#{cassette_name}", 'w') { |f| YAML.dump(request_data, f) }
end


def duplicate_orders(cassette_name:, multiplier:, output_cassette:)
  include ModifyData
  include Anonymizer

  # Load orders
  request_data = YAML.load_file "test/fixtures/vcr_cassettes/#{cassette_name}"
  response_payloads = request_data['http_interactions']

  # Iterate through all requests saved in cassette
  # Replace all sensitive order data with randomly generated information
  response_payloads.each_with_index do |payload, index|
    duplicated_order_list = ModifyData.duplicate_orders(payload['response']['body']['string'], multiplier_constant: multiplier)
    response_payloads[index]['response']['body']['string'] = duplicated_order_list
  end

  # Propagate new information to full request payload in YAML file
  request_data['http_interactions'] = response_payloads
  File.open("test/fixtures/vcr_cassettes/#{output_cassette}", 'w') { |f| YAML.dump(request_data, f) }
end


strip_shop_details(cassette_name: 'authenticate.yml')
strip_order_details(cassette_name: 'orders_from_2010_01_01_to_2015_01_01.yml')
strip_order_details(cassette_name: 'orders_from_2010_01_01.yml')
strip_order_details(cassette_name: 'orders_no_paramaters.yml')
strip_order_details(cassette_name: 'orders_to_2015-06-26.yml')
duplicate_orders(cassette_name: 'orders_from_2010_01_01_to_2015_01_01.yml', multiplier: 3, output_cassette: 'multiple_pages_orders.yml')

