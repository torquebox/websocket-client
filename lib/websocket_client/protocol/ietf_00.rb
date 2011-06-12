require 'socket'
require 'uri'
require 'digest/md5'

module WebSocketClient
  module Protocol
    class Ietf00
  
      attr_reader :source
      attr_reader :sink
  
      def initialize(uri, source, sink)
        @source = source
        @sink   = sink
        perform_http_prolog(uri)
      end

      def perform_http_prolog(uri)
        key1, key2, key3, solution = generate_keys()
  
        sink.write_line "GET #{uri.path} HTTP/1.1"
        sink.write_line "Host: #{uri.host}"
        sink.write_line "Connection: upgrade"
        sink.write_line "Upgrade: websocket"
        sink.write_line "Origin: http://#{uri.host}/"
        sink.write_line "Sec-WebSocket-Key1: #{key1}"
        sink.write_line "Sec-WebSocket-Key2: #{key2}"
        sink.write_line ""
        sink.write_line key3
        sink.flush
        
        while ( ! source.eof? ) 
          line = source.getline
          break if ( line.strip == '' ) 
        end
  
        challenge = source.getbytes( 16 ) 
        source.getline
  
        if ( challenge == solution )
          #
        end
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
        Digest::MD5.digest( input ).bytes.to_a
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
        'tacobob1'
      end
  
    end
  end
end
