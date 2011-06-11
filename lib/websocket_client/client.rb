require 'socket'
require 'uri'
require 'websocket_client/ietf_00'


module WebSocketClient

  DEFAULT_HANDSHAKE = Ietf00

  class DebugSocket
    def initialize(socket)
      @socket = socket
    end

    def method_missing(method, *args)
      puts "> #{method}(#{args.join( ', ')})"
      @socket.__send__( method, *args )
    end
  end

  def self.create(uri,handshake_class=WebSocketClient::DEFAULT_HANDSHAKE,&block)
    Client.new(uri, handshake_class, &block)
  end

  class Client
    attr_reader :uri

    def initialize(uri,handshake_class=WebSocketClient::DEFAULT_HANDSHAKE, &block)
      @handshake_class = handshake_class
      @socket = nil
      @on_message_handler = nil
      @on_disconnect_handler = nil
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
      @socket = TCPSocket.open(uri.host, uri.port)
      puts "> handshaking"
      @handshake = @handshake_class.new( uri, @socket )
      puts "> handshook"
      
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
      @handshake.encode_text_message( msg )
      @socket.flush
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
        @on_disconnect_handler.call( msg ) if @on_disconnect_handler
      end
    end
  
    def start_handler
      @handler_thread = Thread.new(@socket) do |socket|
        msg = ''
        msg_state = :none
        while ( ! socket.eof? )
          c = nil
          if ( socket.respond_to?( :getbyte ) )
            c = socket.getbyte
          else
            c = socket.getc
          end
          puts "> #{c} #{c.class} #{c == 0xff}"
          if ( c == 0x00 ) 
            if ( msg_state == :half_closed )
              puts "> full-closed by server"
              socket.close
              break
            else
              if ( @close_state == :half_closed )
                socket.close
                break
              else
                msg = ''
                msg_state = :none
              end
            end
          elsif ( c == 0xFF ) 
            if ( msg_state == :none )
              msg_state = :half_closed
              puts "> half-closed by server"
            else
              if ( @close_state == :requested )
                @close_state = :half_closed
              else
                on_message( msg ) 
                msg = ''
                msg_state = :none
              end
            end
          else
            if ( @close_state != nil )
              @close_state = nil
            end
            msg_state = :in_progress
            msg << c
          end
        end
        on_disconnect
      end
    end
  
  end
end

