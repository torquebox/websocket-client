
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

    def bytes
      [ 0x00, @text.bytes.to_a, 0xFF ].flatten
    end

  end

  class CloseFrame
    INSTANCE = CloseFrame.new.freeze

    def type
      :close
    end

    def bytes
      [ 0xFF, 0x00 ]
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

    def write_close_frame()
      write_frame( CloseFrame::INSTANCE )
    end

    def write_as_text_frame(text)
      write_frame( TextFrame.new( text ) )
    end

    def write_frame(frame)
      frame.bytes.each do |b|
        @sink.write( b )
      end
      @sink.flush
    end
  end

  class FrameReader

    attr_reader :source
    attr_accessor :debug

    def initialize(source,debug=false)
      @source = source
      @debug = debug
    end

    def eof?
      @source.eof?
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
