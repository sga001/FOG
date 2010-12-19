require 'uds.rb'
require 'lms.rb'
require 'pp'
require 'bloomfilter.rb'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 

XXX TODO
ideally we would split off a second process for each node which would periodically:
- update its neighbours
- generate and send out the digest of the replicas it is holding
- listen for incoming messages
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
    @new_messages = {}
    @cached_messages = {}
  end

  def realID
    return @nid
  end
  
  
  def cache_messages()
    @new_messages.each{|tag, list|
      l = []
      if(@cached_messages.key?(tag))
        l = @cached_messages[tag]
      end
      l+= list
      @cached_messages.store(tag, l)
    }
    @new_messages = {}
  end

  def check()
    @subscriptions.each{|tag|
      @new_messages.store(tag, query(tag))
    }
    list = @new_messages
    cache_messages()

    return list
  end
  
  
  #these are the 1 hop neighbors... they are FogNodes!!!  
  def updateNeighbors (list)
    # the neighbors being passed in are physical neihgbors. neighbors in the
    # routing overlay may be different.  
    @neighbors = list
  end
  
  # synonym for getRouting
  def routing
    return @routing
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

  def publish(tag, message, lifetime, radius, replicas)
    # calls the PUT method of the routing layer. lifetime specifies a lifetime
    # for the message in seconds. radius specifies a radius of applicability--
    # nodes outside this radius from the message will not see it. (this is a
    # hack right now-- it is still stored just not retuned if the radius is
    # exceeded. also, it should be a radius from the originator not the replica
    # host XXX TODO). 
    value = FogDataObject.new(initiator = @nid, message, lifetime, radius)
    @routing.put(tag, value, replicas)
  end
  
  def query(tag)
    # issues 20 LMS GET probes. the number 20 should be dynamic; probes should
    # happen in parallel. 
    message_list =  []
    (1...20).each{
      fog_items, probe = @routing.get(tag)
      if fog_items
        fog_items.each{|item| 
        if @cached_messages.key?(tag)
          l = @cached_messages[tag]
          if not l.include?(item.message)
            message_list.push(item.message)
          end
        else
          message_list.push(item.message)
        end 
       }
       end
    }
    
    return message_list.uniq
  end

  def cached()
    return @cached_messages
  end
  def remind() #is this really necessary
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
    # add the item if new or update the item if that key already exists in the
    # buffer
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
  This class represents a Fog Data Object which is composed of: Initiator,
  Message, Lifetime, and Radius
=end
class FogDataObject
  def initialize(initiator, message, lifetime, radius)
    @initiator, @message, @radius = initiator, message, radius
    @created = Time.now
    @expiry = Time.now + lifetime
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


