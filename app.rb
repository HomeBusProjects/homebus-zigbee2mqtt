# coding: utf-8

require 'homebus'
require 'dotenv/load'

require 'json'

class Zigbee2MQTTHomebusApp < Homebus::App
  DDC_AIR_SENSOR       = 'org.homebus.experimental.air-sensor'
  DDC_CONTACT_SENSOR   = 'org.homebus.experimental.contact-sensor'
  DDC_LIGHT_SENSOR     = 'org.homebus.experimental.light-sensor'
  DDC_OCCUPANCY_SENSOR = 'org.homebus.experimental.occupancy-sensor'
  DDC_VOC_SENSOR       = 'org.homebus.experimental.voc-sensor'
  DDC_DIAGNOSTIC       = 'org.homebus.experimental.diagnostic'
  DDC_SYSTEM           = 'org.homebus.experimental.system'

  def initialize(options)
    @options = options
    @devices = []
    super
  end

  def update_interval
    60
  end

  def setup!
    @zigbee_broker_url = ENV['ZIGBEE_BROKER_URL']

    zigbee_mqtt_client = MQTT::Client.connect(@zigbee_broker_url)

    zigbee_mqtt_client.subscribe 'zigbee2mqtt/bridge/devices'

    # if needed we can request a refresh of the devices by publishing to
    # 'zigbee2mqtt/bridge/config/devices/get'
    # but devices are published with retain so if all is working well we should see them
    zigbee_mqtt_client.get do |topic, msg|
      json = JSON.parse(msg, symbolize_names: true)

      if @options[:verbose]
        puts 'zigbee2mqtt/bridge/devices --> '
        pp json
      end

      zigbee_map = _get_zigbee_map(json)
      if @options[:verbose]
        puts 'zigbee_map is '
        pp zigbee_map
      end

      _process_zigbee_differences(zigbee_map)
      break
    end
  end

  # published to zigbee2mqtt/Garage Temperature
  #
  # {"battery":100,"illuminance":623,"illuminance_lux":623,"linkquality":255,"occupancy":true,"temperature":26,"voltage":3155}
  # {"contact":true,"linkquality":255}
  # {"battery":100,"humidity":44.58,"linkquality":255,"pressure":1030.3,"temperature":21.01,"voltage":3025}
  # {"battery":0,"humidity":44.56,"linkquality":255,"temperature":21.55,"voc":242,"voltage":2800}
  def work!
    zigbee_mqtt_client = MQTT::Client.connect(@zigbee_broker_url)
    zigbee_mqtt_client.subscribe 'zigbee2mqtt/#'
    zigbee_mqtt_client.get do |topic, encoded_msg|
      if ['zigbee2mqtt/bridge/groups', 'zigbee2mqtt/bridge/extensions', 'zigbee2mqtt/bridge/config', 'zigbee2mqtt/bridge/info'].include? topic
        next
      end

      if encoded_msg == 'online'
        next
      end

      msg = JSON.parse encoded_msg, symbolize_names: true

      if @options[:verbose]
        pp topic, msg
      end

      # should "reprocess" devices here and add new ones and delete removed ones
      if topic == 'zigbee2mqtt/bridge/devices'
        #        _process_devices(msg)
        next
      end

      zigbee_id = _get_zigbee_id(topic)
      device = _find_device(zigbee_id)
      unless device
        puts "no device found #{zigbee_id}"
        next
      end

      if msg.has_key?(:occupancy)
        _process_occupancy(device, msg)
      end

      if msg.has_key?(:contact)
        _process_contact(device, msg)
      end

      if msg.has_key?(:humidity)
        _process_air(device, msg)
      end

      if msg.has_key?(:illuminance_lux)
        _process_light(device, msg)
      end

      if msg.has_key?(:voc)
        _process_voc(device, msg)
      end
    end

    sleep update_interval
  end

  def _get_zigbee_id(topic)
    m = topic.match /zigbee2mqtt\/(.+)$/
    return m[1]
  end

  def _process_air(device, msg)
    payload = {
      temperature: msg[:temperature],
      humidity: msg[:humidity]
    }

    if msg[:pressure]
      payload[:pressure] = msg[:pressure]
    end

    if @options[:verbose]
      puts DDC_AIR_SENSOR, payload
    end

    device.publish! DDC_AIR_SENSOR, payload
  end

  def _process_voc(device, msg)
    payload = {
      voc: msg[:voc]
    }

    if @options[:verbose]
      puts DDC_VOC_SENSOR, payload
    end

    device.publish! DDC_VOC_SENSOR, payload
  end

  def _process_light(device, msg)
    payload = {
      lux: msg[:illuminance_lux]
    }

    if @options[:verbose]
      puts DDC_LIGHT_SENSOR, payload
    end

    device.publish! DDC_LIGHT_SENSOR, payload
  end


  def _process_contact(device, msg)
    payload = {
      contact: msg[:contact]
    }

    if @options[:verbose]
      puts DDC_CONTACT_SENSOR, payload
    end

    device.publish! DDC_CONTACT_SENSOR, payload
  end

  def _process_occupancy(device, msg)
    payload = {
      occupancy: msg[:occupancy]
    }

    if @options[:verbose]
      puts DDC_OCCUPANCY_SENSOR, payload
    end

    device.publish! DDC_OCCUPANCY_SENSOR, payload
  end

  def _find_device(name)
    @devices.select { |d| d.name == name }[0]
  end

  def _get_zigbee_map(json)
    zigbee_map = {}
    json.each do |d|
      next unless d[:interview_completed]
      next if d[:friendly_name] == 'Coordinator'

      zigbee_map[d[:friendly_name]] = {
        mac_address: d[:ieee_address],
        manufacturer: d[:definition][:vendor],
        model: d[:definition][:model]
      }
    end

    return zigbee_map
  end

  def _process_zigbee_differences(zigbee_map)
    zigbee_map.each do |key, value|
      unless _find_device(value[:mac_address])
        @devices << Homebus::Device.new(name: key,
                                        manufacturer: value[:manufacturer],
                                        model: value[:model],
                                        serial_number: value[:mac_address])
      end
    end
  end

  def name
    'Homebus Zigbee2MQTT publisher'
  end

  def publishes
    [ DDC_AIR_SENSOR, DDC_CONTACT_SENSOR, DDC_LIGHT_SENSOR, DDC_OCCUPANCY_SENSOR, DDC_VOC_SENSOR, DDC_DIAGNOSTIC, DDC_SYSTEM ]
  end

  def devices
    @devices
  end
end
