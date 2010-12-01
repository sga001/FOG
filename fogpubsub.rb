require 'uds.rb'
require 'lms.rb'
require 'pp'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 
=end


class FogNode
  def initialize(nid, x=nil, y=nil, subscriptions=nil, routing, lambda_, 
                 hops, buffer_size, max_failures)
    @nid = nid
    @x = x 
    @y = y
    @subscriptions = subscriptions
    @max_buffer = buffer_size ||= rand(20)
    @buffer = {}
    # expects routing interface to implement put, get
    @routing = routing(@nid, hops, lambda_, @buffer, @max_buffer, max_failures) 
    @neighbors = nil
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

  def publish(nid, item, tag, expiry, radius, replicas)
    # currently just calls the PUT method of the routing/storage layer
    @routing.put(nid, item, tag, replicas)
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



end


