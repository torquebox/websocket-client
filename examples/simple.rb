#!/usr/bin/env ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'web_socket_client'

#WebSocketClient.connect( 'ws://localhost:8081/websockets/' ) do |client|
#end

WebSocketClient::Client.new( 'ws://localhost:8081/websockets/' ) do |client|
  client.on_message do |msg|
    puts "received #{msg}"
  end

  client.connect() do |client|
    puts "sending"
    client.send( "HOWDY-1" )
    #client.send( "HOWDY-2" )
    #client.send( "HOWDY-3" )
    sleep(1)
  end
end
