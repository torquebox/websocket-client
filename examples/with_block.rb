#!/usr/bin/env ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'websocket_client'

## Create a disconnected client
WebSocketClient.create( 'ws://localhost:8081/websockets/' ) do |client|

  ## Set up the message handler before connecting
  client.on_message do |msg|
    puts "received #{msg}"
  end

  ## Connect
  client.connect() do |client|

    ## Use the connected client
    puts "sending"
    client.send( "HOWDY-1" )
    client.send( "HOWDY-2" )
    client.send( "HOWDY-3" )
    sleep(1)
  end

  ## Disconnected
end
