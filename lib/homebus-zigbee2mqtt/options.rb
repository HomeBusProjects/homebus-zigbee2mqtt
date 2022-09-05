require 'homebus/options'

require 'homebus-zigbee2mqtt/version'

class HomebusZigbee2mqtt::Options < Homebus::Options
  def app_options(op)
  end

  def banner
    'HomeBus Netatmo publisher'
  end

  def version
    HomebusZigbee2mqtt::VERSION
  end

  def name
    'homebus-zigbee2mqtt'
  end
end
