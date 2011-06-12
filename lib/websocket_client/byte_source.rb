
module WebSocketClient

  class ByteSource
    def getbytes(num)
      bytes = []
      1.upto( num ) do
        break if ( eof? )
        bytes << getbyte()
      end
      bytes
    end
  end

  class BufferedByteSource < ByteSource
    def initialize(source)
      @source = source
      @buffer = []
    end

    def getbyte
      return @source.getbyte if @buffer.empty?
      @buffer.shift
    end

    def peekbyte(index=0)
      while ( @buffer.size < (index+1) )
        return nil if (  @source.eof? )
        @buffer << @source.getbyte
      end
      return @buffer[index] 
    end

    def eof?
      return @source.eof? if @buffer.empty?
      false
    end

    def getline
      line = ''
      while ( ! eof? )
        b = getbyte 
        case ( b )
          when 0x0D then # carriage-return
            if peekbyte == 0x0A # newline
              getbyte # consume it also
            end
            break
          when 0x0A then # newline
            break
          else
            line << b
        end
      end
      return line
    end
  

  end

  class SocketByteSource < ByteSource
    def initialize(socket)
      @socket = socket
      if ( socket.respond_to? :getbyte )
        alias :getbyte :getbyte_19
      else
        alias :getbyte :getbyte_18
      end
    end

    def getbyte_18
      @socket.getc
    end

    def getbyte_19
      @socket.getbyte
    end

    def eof?
      @socket.eof?
    end

  end
 
  class ArrayByteSource < ByteSource
    def initialize(array)
      @array = array
      @cur = 0
    end

    def getbyte
      b = @array[@cur]
      @cur += 1
      b
    end

    def eof?
      ( @cur >= @array.size )
    end

  end
end
