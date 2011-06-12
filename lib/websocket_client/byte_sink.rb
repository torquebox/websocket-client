
module WebSocketClient

  class ByteSink

    CR = 0x0D
    NL = 0x0A

    def write_line(line)
      line.bytes.each do |b|
        write( b )
      end
      write( CR )
      write( NL )
    end

    def flush
    end 
  end

  class SocketByteSink < ByteSink
    def initialize(socket)
      @socket = socket
    end

    def flush
      @socket.flush
    end
  end 

  class ArrayByteSink < ByteSink
    def initialize()
      @sink = []
    end

    def write(byte)
      @sink << byte
    end

    def bytes
      @sink
    end
  end
end
