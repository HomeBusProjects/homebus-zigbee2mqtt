require 'homebus/options'

class Zigbee2MQTTHomebusOptions < Homebus::Options
  def app_options(op)
  end

  def banner
    'HomeBus Netatmo publisher'
  end

  def version
    '0.0.1'
  end

  def name
    'homebus-netatmo'
  end
end
