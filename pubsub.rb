require 'uds.rb'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 
=end

class PSNode
  # Publish/Subscribe nodes extend their lower level node by adding a list of
  # subscriptions. 

  def initialize(node, subscriptions=nil)
    @node = node
    @subscriptions = subscriptions
  end

  def addSubscription(tag)
    @subscriptions.push(tag) if not @subscriptions.include?(tag)
  end 

  def deleteSubscription(tag)
    @subscriptions.delete(tag)
  end

end


class PubSub

  def initialize(routing_layer)
    @routing = routing_layer
    @psNodes = {} 
    routing_layer.nodes.each { |nid, node|
      # if nodes already exist, keep the same node IDs 
      @psNodes[nid] = PSNode.new(node, subscriptions=nil)
    }    
  end 

  def publish(nid, item, tag, replicas)
    # currently just calls the PUT method of the routing/storage layer
    @routing.put(nid, item, tag, replicas)
  end

  def subscribe(nid, tag)
    # add tag-based subscription information to a given node
    @psNodes[nid].addSubscription(tag) 
  end

  def inspect(nid, publication)
  end
  
  def addNode(x=nil, y=nil, buffer_size=nil, subscriptions=[])
    id = @routing_layer.addNode(x,y,buffer_size)
    @psNodes[id] = PSNode.new(@routing_layer.nodes[id], subscriptions)
  end
  

end


