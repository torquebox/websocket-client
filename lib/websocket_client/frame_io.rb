
require 'websocket_client/byte_source'
require 'websocket_client/byte_sink'

module WebSocketClient

  class TextFrame

    attr_accessor :text

    def initialize(text)
      @text = text
    end

    def type
      :text
    end

  end

  class CloseFrame
    INSTANCE = CloseFrame.new.freeze

    def type
      :close
    end

    private
    def initialize()
    end
  end

  class FrameWriter
    attr_reader :sink
    attr_accessor :debug

    def initialize(sink,debug=false)
      @sink = sink
      @debug = debug
    end

    def write_frame(frame)
      case ( frame )
        when TextFrame:
          @sink.write( 0x00 )
          frame.text.bytes.each do |b|
            @sink.write( b )
          end
          @sink.write( 0xFF )
        when CloseFrame:
          puts "> writing close frame" if debug
          @sink.write( 0xFF )
          @sink.write( 0x00 )
      end
    end
  end

  class FrameReader

    attr_reader :source
    attr_accessor :debug

    def initialize(source,debug=false)
      @source = source
      @debug = debug
    end

    def read_frame()
      buffer = nil
      state = :none
      while ( ! source.eof? )
        b = source.getbyte
        puts "> [#{b}]" if debug
        case ( b )
          when 0x00
            if ( state == :half_closed )
              return CloseFrame::INSTANCE
            end
            buffer = ''
          when 0xFF
            if ( ! buffer.nil? )
               return TextFrame.new( buffer )
            else
              puts "> half closed" if debug
              state = :half_closed
            end
          else
            buffer << b
        end
      end
      nil
    end

  end

end
