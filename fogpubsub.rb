require 'uds.rb'
require 'lms.rb'
require 'pp'
require 'bloomfilter.rb'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 
=end


class FogNode
  def initialize(nid, routing, lambda_, hops, buffer_size, max_failures, x, y, subscriptions=nil)
    @nid = nid
    @x = x
    @y = y
    @subscriptions = subscriptions || []
    @max_buffer = buffer_size ||= rand(20)
    @current_buffer = 0
    @buffer = {}
    @digest = BloomFilter.new(512, 10) # 512 bits, 10 hash functions
    # expects routing interface to implement put, get
    @routing = routing.new(self, hops, lambda_, max_failures) 
    # initialize neighbor list
    @neighbors = [] #-> FogNodes
  end

  def realID
    return @nid
  end

  #these are the 1 hop neighbors... they are FogNodes!!!
  def updateNeighbors (list)
    @neighbors = list
  end
  
  def getRouting()
    return @routing
  end
  
  def getNeighbors()
    return @neighbors
  end

  # --------------------------------------------------
  # publish, subscribe and fog application layer stuff
  # --------------------------------------------------

  def deliver
  end

  def store
  end

  def publish(tag, message, expiry, radius, replicas)
    # currently just calls the PUT method of the routing layer   
    value = FogDataObject.new(message, expiry, radius)
    @routing.put(tag, value, replicas)
  end

  def subscribe(nid, tag)
    # add tag-based subscription information to a given node
    @psNodes[nid].addSubscription(tag) 
  end

  def inspect(nid, publication)
  end
  
  def query(tag)
    #currently just calls the GET method 20 times of the routing layer
    message_list =  []
    (1...20).each{
      fog_items, probe = @routing.get(tag)
      if fog_items
        fog_items.each{|item| 
        message_list.push(item.message)
       }
       end
    }
    
    return message_list.uniq
  end

  def remind()
    # remind your neighbours of the messages you have by issuing a digest to
    # them. 
  end

  def addSubscription(tag)
    @subscriptions.push(tag) if not @subscriptions.include?(tag)
  end 

  def deleteSubscription(tag)
    @subscriptions.delete(tag)
  end

  # --------------------------------------------------
  # Location methods
  # --------------------------------------------------

  def x
    return @x
  end

  def y
    return @y
  end

  def x=(value)
    @x = value
  end 

  def y=(value)
    @y = value
  end
  
  def to_s
    return "[" + @x.to_s + "," + @y.to_s + "]"
  end

  def distance(x, y)
    return Math.sqrt((@x - x)**2 + (@y - y)**2)
  end
  
  # --------------------------------------------------
  # Physical Storage Methods
  # --------------------------------------------------

   
   def bufferAdd(k, item)
    unless bufferFull?
      if containsKey?(k)
        list = @buffer[k]
        list.push(item)
        @buffer.store(k, list)
      else
        list = []
        list.push(item)
        @buffer.store(k, list)
        @digest.insert(k)
      end
      @current_buffer += 1 
    else
      raise "Max buffer size exceeded"
    end
  end
  
  def containsKey?(k)
    return @buffer.key?(k)
  end
  
  def containsData?(item)
    @buffer.each{|key, value|
      value.each{|data|
        if data == item
          return true
        end
      }
    }
    return false
  end

  def bufferFull?
    if @current_buffer >= @max_buffer
      return true
    else
      return false
    end
  end

  def bufferLength()
    return @current_buffer
  end
  
  def retrieve(k)
    return @buffer[k]
  end

  def digest()
    return @digest
  end

end

=begin
  This class represents a Fog Data Object which is composed of: Tag, Message, Expire Date and Radius
=end
class FogDataObject
  def initialize(message, expiry, radius)
    @message, @expiry, @radius = message, expiry, radius
  end
  
  def message
    return @message
  end
  
  def expiry
    return @expiry
  end
  
  def radius
    return @radius
  end
end


