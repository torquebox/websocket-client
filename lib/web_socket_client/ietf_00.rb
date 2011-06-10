require 'socket'
require 'uri'

module WebSocketClient

  class Ietf00

    def initialize(uri, socket)
      @socket = socket
      key1, key2, key3, solution = generate_keys()

      @socket.puts "GET #{uri.path} HTTP/1.1"
      @socket.puts "Host: #{uri.host}"
      @socket.puts "Connection: upgrade"
      @socket.puts "Upgrade: websocket"
      @socket.puts "Origin: http://#{uri.host}/"
      @socket.puts "Sec-WebSocket-Version: 8"
      @socket.puts "Sec-WebSocket-Key1: #{key1}"
      @socket.puts "Sec-WebSocket-Key2: #{key2}"
      @socket.puts ""
      @socket.print key3
      @socket.puts ""
      @socket.flush
      
      while ( ! @socket.eof? ) 
        line = @socket.gets
        break if ( line.strip == '' ) 
      end
    end

    def encode_text_message(msg)
      @socket.putc 0x00
      @socket.print msg
      @socket.putc 0xFF
      @socket.flush
    end

    def generate_keys()
      key1 = generate_header_key
      key2 = generate_header_key
      key3 = generate_content_key
      [ key1, key2, key3, solve( key1, key2, key3 ) ]
    end

    def solve(key1, key2, key3)
      int1 = key1.gsub( /[^0-9]/, '' ).to_i / key1.gsub( /[^ ]/, '' ).size
      int2 = key2.gsub( /[^0-9]/, '' ).to_i / key2.gsub( /[^ ]/, '' ).size
      [ int1, int2 ].pack( 'CC' ) + key3
    end

    def generate_header_key
      key = '' 
      1.upto(32) do 
        key << rand(90) + 32
      end
      1.upto( rand(10) + 1 ) do
        key[rand(key.size),1] = ' '
      end
      key
    end

    def generate_content_key
      key = ''
      1.upto(8) do 
        key << rand(52) + 65
      end
      key
    end

  end

end
