#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path('../../lib/shopify_dashboard_plus.rb', __FILE__)
require 'vegas'

Vegas::Runner.new(Sinatra::Application, 'shopify_dashboard_plus')

