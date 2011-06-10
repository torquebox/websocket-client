require 'socket'
require 'uri'
require 'web_socket_client/ietf_00'



module WebSocketClient
  class DebugSocket
    def initialize(socket)
      @socket = socket
    end

    def method_missing(method, *args)
      puts "> #{method}(#{args.join( ', ')})"
      @socket.__send__( method, *args )
    end
  end

  class Client
    attr_reader :uri

    def initialize(uri,handshake_class=Ietf00, &block)
      @handshake_class = handshake_class
      @socket = nil
      @on_message_handler = nil
      @handler_thread = nil
      @close_state = nil
      case ( uri )
        when String
          @uri = URI.parse( uri )
        else
          @uri = uri
      end
      block.call( self ) if block
    end
  
    def connect(&block)
      key = "86 753 09"

      @socket = TCPSocket.open(uri.host, uri.port)
      @handshake = @handshake_class.new( uri, @socket )
      
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
      @socket.puts 0xFF
      @socket.putc 0x00
      @close_state = :requested
    end
  
    def send(msg)
      @socket.print @handshake.encode_text_message( msg )
      @socket.flush
    end

    def wait_forever()
      @handler_thread.join
    end

    def on_message(msg=nil,&block)
      if ( block ) 
        @on_message_handler = block
      else
        @on_message_handler.call( msg ) if @on_message_handler
      end
    end
  
    def start_handler
      @handler_thread = Thread.new(@socket) do |socket|
        msg = ''
        while ( ! socket.eof? )
          c = socket.getc
          if ( c == 0x00 ) 
            if ( @close_state == :half_closed )
              socket.close
              break;
            else
              msg = ''
            end
          elsif ( c == 0xFF ) 
            if ( @close_state == :requested )
              @close_state = :half_closed
            else
              on_message( msg ) 
            end
          else
            if ( @close_state != nil )
              @close_state = nil
            end
            msg << c
          end
        end
      end
    end
  
  end
end
