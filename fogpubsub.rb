require 'uds.rb'
require 'lms.rb'
require 'pp'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 
=end


class FogNode
  def initialize(nid, routing, lambda_, hops, buffer_size, max_failures, god, x, y, subscriptions=nil)
    @nid = nid
    @x = x
    @y = y
    @subscriptions = subscriptions || []
    @max_buffer = buffer_size ||= rand(20)
    @buffer = {}
    @digest = BloomFilter.new(512, 10) # 512 bits, 10 hash functions
    @god = god
    # expects routing interface to implement put, get
    @routing = routing.new(@nid, hops, lambda_, max_failures, @god) 
    # initialize neighbor list
    @routing.neighbours_update() 
  end

  def realID
    return @nid
  end

  # --------------------------------------------------
  # publish, subscribe and fog application layer stuff
  # --------------------------------------------------

  def deliver
  end

  def store
  end

  def publish(item, tag, expiry, radius, replicas)
    # currently just calls the PUT method of the routing/storage layer
    key = Digest::SHA1.hexdigest(item.to_s) #this makes it a unique key
    value = FogDataObject.new(item, tag, expiry, radius)
    @routing.put(key, value, replicas)
  end

  def subscribe(nid, tag)
    # add tag-based subscription information to a given node
    @psNodes[nid].addSubscription(tag) 
  end

  def inspect(nid, publication)
  end
  
  def query(nid, q)
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

  # --------------------------------------------------
  # Physical Storage Methods
  # --------------------------------------------------

   
   def bufferAdd(k, item)
    unless bufferFull?
      @buffer.store(k, item)
      @digest.insert(k)
    else
      raise "Max buffer size exceeded"
    end
  end
  
  def contains?(k)
    return @buffer.key?(k)
  end

  def bufferFull?
    if @buffer.length >= @max_buffer
      return true
    else
      return false
    end
  end

  def bufferLength()
    return @buffer.length
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
  def initialize(tag, message, expiry, radius)
    @tag, @message, @expiry, @radius = tag, message, expiry, radius
  end
  
  def tag
    return @tag
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


