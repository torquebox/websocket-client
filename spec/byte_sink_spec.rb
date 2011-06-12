load 'spec_helper.rb'

require 'websocket_client/byte_sink'

describe WebSocketClient::ByteSink do

  it "should append CR NL" do
    sink = WebSocketClient::ArrayByteSink.new
    sink.write_line( "Howdy" )
    sink.bytes.should == "Howdy\r\n".bytes.to_a
  end

end
