require 'socket'
require 'uri'

class WebSocketClient

  attr_reader :uri

  def initialize(uri,&block)
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
    @socket.puts "GET #{uri.path} HTTP/1.1"
    @socket.puts "Host: #{uri.host}"
    @socket.puts "Connection: upgrade"
    @socket.puts "Upgrade: websocket"
    @socket.puts "Origin: http://#{uri.host}/"
    @socket.puts "Sec-WebSocket-Key1: #{key}"
    @socket.puts "Sec-WebSocket-Key2: #{key}"
    @socket.puts "Sec-WebSocket-Version: 8"
    @socket.puts ""
    @socket.print "absjekdjs"

    while ( ! @socket.eof? ) 
      line = @socket.gets
      break if ( line.strip == '' ) 
    end
    
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
    @socket.putc 0x00
    @socket.print msg
    @socket.putc 0xFF
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
