# homebus-zigbee2mqtt

Homebus publisher that takes data from [Zigbee2MQTT](https://www.zigbee2mqtt.io) and republishes it on a Homebus network.

This version is extremely rudimentary. In particular it does not currently process Zigbee device deletions and additions.

## Configuration

Configure access to the MQTT broker used by Zigbee2MQTT by putting the following line in `.env`:
```
ZIGBEE_BROKER_URL=mqtts://USERNAME:PASSWORD@HOSTNAME:PORT
```

Change `mqtts` to `mqtt` to use insecure, unencrypted MQTT.
