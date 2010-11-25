class Node
  
  def initialize(host, port)
   @host, @port = host, port
  end
  
  def start()
      begin
        server = TCPServer.new(@host, @port)
      rescue => reason
        puts "Can't create server: " + reason
        exit
      end
      
      begin
        while true
          Thread.start(server.accept) do |session|
            begin
              while data = session.gets
                session.puts data #Echo server haha :p don't hate
              end
            rescue SocketError => reason
          
            ensure
              session.close if session
            end
          end
        end
        
        rescue SocketError => reason
          puts "Server socket has failed: #{reason}"
        rescue Interrupt
           server.close
      end
  end
end