require 'socket'
require 'uri'
require 'digest/md5'

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
      challenge = @socket.read( 16 ) 
      if ( challenge == solution )
        puts "success!"
      end
      #dump 'solution', solution
      #dump 'challenge', challenge
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
      int1 = solve_header_key( key1 )
      int2 = solve_header_key( key2 )
      input = int1.to_s + int2.to_s + key3
      Digest::MD5.digest( input )
    end

    def solve_header_key(key)
      key_digits = key.strip.gsub( /[^0-9]/, '').to_i
      key_spaces = key.strip.gsub( /[^ ]/, '').size
      solution = key_digits / key_spaces
      solution
    end

    def generate_header_key
      key = '' 
      1.upto(32) do 
        key << rand(90) + 32
      end
      1.upto( rand(10) + 2 ) do
        key[rand(key.size-1)+1,1] = ' '
      end
      1.upto( rand(10) + 2 ) do
        key[rand(key.size-1)+1,1] = rand(9).to_s
      end
      key
    end

    def generate_content_key
      key = []
      'tacobob1'.each_byte do |byte|
        key << byte
      end
      key.pack('cccccccc')
    end

  end

end
