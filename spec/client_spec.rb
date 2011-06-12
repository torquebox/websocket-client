load 'spec_helper.rb'

require 'websocket_client'
require 'websocket_client/byte_source'

describe WebSocketClient::Client do

  before :each do
    @inbound = []
    @discounnted = false
  end

  it "should read a single eof frame and notify disconnect" do
    source = WebSocketClient::ArrayByteSource.new( WebSocketClient::CloseFrame::INSTANCE.bytes )

    client = WebSocketClient::Client.new( nil ) 
    client.internal_connect( source, nil )

    client.on_message do |message|
      @inbound << message
    end

    client.on_disconnect do
      @disconnect = true
    end

    client.run_handler_loop
    @disconnect.should be_true
  end

  it "should read a sequence of text frames and notify, then an eof frame and notify disconnect" do
    byte_sequence = [
      WebSocketClient::TextFrame.new( "The gum you like is coming back into style" ).bytes,
      WebSocketClient::TextFrame.new( "How's Annie?" ).bytes,
      WebSocketClient::CloseFrame::INSTANCE.bytes,
    ].flatten

    source = WebSocketClient::ArrayByteSource.new( byte_sequence )

    client = WebSocketClient::Client.new( nil ) 
    client.internal_connect( source, nil )

    client.on_message do |message|
      @inbound << message
    end

    client.on_disconnect do
      @disconnect = true
    end

    client.run_handler_loop
    @inbound.size.should == 2
    @inbound[0].should == "The gum you like is coming back into style"
    @inbound[1].should == "How's Annie?"
    @disconnect.should be_true
  end

  it "should send a correct close frame upon closure" do
    sink = WebSocketClient::ArrayByteSink.new

    client = WebSocketClient::Client.new( nil ) 
    client.internal_connect( nil, sink )
    client.send( "Take my little hand!" )

    sink.bytes.should == [ 0x00, "Take my little hand!".bytes.to_a, 0xFF ].flatten
  end

end
