#!/usr/bin/env ruby

require './options'
require './app'

zigbee_app_options = Zigbee2MQTTHomebusOptions.new

zigbee = Zigbee2MQTTHomebusApp.new zigbee_app_options.options
#zigbee.setup!
#zigbee.work!
zigbee.run!
