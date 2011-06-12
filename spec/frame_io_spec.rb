
load 'spec_helper.rb'

require 'websocket_client/frame_io'

describe WebSocketClient::FrameReader do

  it "should parse close frames" do
    buffer = [ 0xFF, 0x00 ]
    source = WebSocketClient::ArrayByteSource.new( buffer )
    reader = WebSocketClient::FrameReader.new( source, true )
    frame = reader.read_frame
    frame.should_not be_nil
    frame.type.should == :close
    source.should be_eof
  end

  it "should parse text frames" do
    buffer = text_buffer( "I like the cut of your jib" )
    puts buffer.inspect
    source = WebSocketClient::ArrayByteSource.new( buffer )
    reader = WebSocketClient::FrameReader.new( source, true )
    frame = reader.read_frame
    frame.should_not be_nil
    frame.type.should == :text
    frame.text.should == "I like the cut of your jib"
    source.should be_eof
  end

  def text_buffer(text)
    [ 0x00, text.to_s.bytes.to_a, 0xFF ].flatten
  end
end

describe WebSocketClient::FrameWriter do

  it "should write close frames" do
    sink = WebSocketClient::ArrayByteSink.new
    writer = WebSocketClient::FrameWriter.new( sink, true )
    writer.write_frame( WebSocketClient::CloseFrame::INSTANCE )
    sink.bytes.should == [ 0xFF, 0x00 ]
  end

  it "should write text frames" do
    sink = WebSocketClient::ArrayByteSink.new
    writer = WebSocketClient::FrameWriter.new( sink, true )
    writer.write_frame( WebSocketClient::TextFrame.new( "On the third day, he turned into a zombie" ) )
    sink.bytes.should == [ 0x00, "On the third day, he turned into a zombie".bytes.to_a, 0xFF ].flatten
  end

end
