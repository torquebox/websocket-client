load 'spec_helper.rb'

require 'websocket_client/byte_source'

describe WebSocketClient::BufferedByteSource do

  it "should be able to read lines with only newlines" do
     text = "if I had a hammer\nI'd hit folk-singers with it"
     base_source = WebSocketClient::ArrayByteSource.new( text )
     source = WebSocketClient::BufferedByteSource.new( base_source )
     source.getline.should == "if I had a hammer"
     source.getline.should == "I'd hit folk-singers with it"
     source.should be_eof
  end


  it "should be able to read lines with carraige-returns and newlines" do
     text = "if I had a hammer\r\nI'd hit folk-singers with it"
     base_source = WebSocketClient::ArrayByteSource.new( text )
     source = WebSocketClient::BufferedByteSource.new( base_source )
     source.getline.should == "if I had a hammer"
     source.getline.should == "I'd hit folk-singers with it"
     source.should be_eof
  end

  it "should be able to read lines with only carraige-returns, for good measure" do
     text = "if I had a hammer\rI'd hit folk-singers with it"
     base_source = WebSocketClient::ArrayByteSource.new( text )
     source = WebSocketClient::BufferedByteSource.new( base_source )
     source.getline.should == "if I had a hammer"
     source.getline.should == "I'd hit folk-singers with it"
     source.should be_eof
  end

  it "should be able to read lines with trailing carriage-returns" do
     text = "if I had a hammer\rI'd hit folk-singers with it\r"
     base_source = WebSocketClient::ArrayByteSource.new( text )
     source = WebSocketClient::BufferedByteSource.new( base_source )
     source.getline.should == "if I had a hammer"
     source.getline.should == "I'd hit folk-singers with it"
     source.should be_eof
  end

end
