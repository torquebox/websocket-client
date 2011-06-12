require 'socket'
require 'uri'
require 'websocket_client/ietf_00'
require 'websocket_client/frame_io'


module WebSocketClient

  DEFAULT_HANDSHAKE = Ietf00

  def self.create(uri,handshake_class=WebSocketClient::DEFAULT_HANDSHAKE,&block)
    Client.new(uri, handshake_class, &block)
  end

  class Client
    attr_reader :uri

    attr_reader :source
    attr_reader :sink

    def initialize(uri,handshake_class=WebSocketClient::DEFAULT_HANDSHAKE, &block)
      @handshake_class       = handshake_class
      @on_message_handler    = nil
      @on_disconnect_handler = nil
      @handler_thread        = nil
      @uri                   = cleanse_uri( uri )

      block.call( self ) if block
    end

    def cleanse_uri(uri)
      return URI.parse( uri ) if ( String === uri )
      uri
    end
  
    def connect(&block)
      socket = TCPSocket.open(uri.host, uri.port)
      @source = SocketByteSource.new( socket )
      @sink   = SocketByteSink.new( socket )
      @handshake = @handshake_class.new( uri, @source, @sink )

      internal_connect(source, sink, &block)
      run_client
    end

    def internal_connect(source, sink, &block)
      @frame_reader = FrameReader.new( source )
      @frame_writer = FrameWriter.new( sink )
    end

    def run_client()
      start_handler
      if ( block )
        begin
          block.call( self ) 
        ensure
          disconnect()
        end
      end
    end
  
    def disconnect
      @frame_writer.write_close_frame() 
    end
  
    def send(text)
      @frame_writer.write_as_text_frame( text )
    end

    def wait_forever()
      @handler_thread.join
    end

    def on_message(msg=nil,&block)
      if ( block ) 
        @on_message_handler = block
      else
        puts "> on_message #{msg}"
        @on_message_handler.call( msg ) if @on_message_handler
      end
    end

    def on_disconnect(&block)
      if ( block )
        @on_disconnect_handler = block
      else
        puts "> on_disconnect"
        @on_disconnect_handler.call() if @on_disconnect_handler
      end
    end
  
    def start_handler
      @handler_thread = Thread.new() do
        handler_loop
      end
    end

    def run_handler_loop
      while ( ! @frame_reader.eof? )
        frame = @frame_reader.read_frame
        case ( frame.type )
          when :text
            on_message( frame.text )
          when :close
            break
        end
      end
      on_disconnect
    end
  
  end
end

