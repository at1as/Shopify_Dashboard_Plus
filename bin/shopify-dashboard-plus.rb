#!/usr/bin/env ruby

require File.expand_path('../../lib/shopify-dashboard-plus.rb', __FILE__)
require 'vegas'

Vegas::Runner.new(Sinatra::Application, 'shopify-dashboard-plus')

