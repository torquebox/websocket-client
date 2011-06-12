require 'socket'
require 'uri'
require 'websocket_client/frame_io'
require 'websocket_client/protocol/ietf_00'


module WebSocketClient

  DEFAULT_HANDSHAKE = Protocol::Ietf00

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
      @source = BufferedByteSource.new( SocketByteSource.new( socket ) )
      @sink   = SocketByteSink.new( socket )
      @handshake = @handshake_class.new( uri, @source, @sink )

      internal_connect(source, sink)
      run_client( &block )
    end

    def internal_connect(source, sink)
      @frame_reader = FrameReader.new( source )
      @frame_writer = FrameWriter.new( sink )
    end

    def run_client(&block)
      on_connect
      start_handler
      if ( block )
        begin
            block.call( self ) 
        ensure
          disconnect()
        end
      end
    end
  
    def disconnect(wait_for=false)
      @frame_writer.write_close_frame() 
      wait_for_disconnect if wait_for
    end
  
    def send(text)
      @frame_writer.write_as_text_frame( text )
    end

    def wait_for_disconnect()
      @handler_thread.join
    end

    def on_connect(&block)
      if ( block )
        @on_connect_handler = block
      else
        @on_connect_handler.call() if @on_connect_handler
      end
    end

    def on_message(msg=nil,&block)
      if ( block ) 
        @on_message_handler = block
      else
        @on_message_handler.call( msg ) if @on_message_handler
      end
    end

    def on_disconnect(&block)
      if ( block )
        @on_disconnect_handler = block
      else
        @on_disconnect_handler.call() if @on_disconnect_handler
      end
    end
  
    def start_handler
      @handler_thread = Thread.new() do
        run_handler_loop
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

