require 'digest/md5'
require 'uds.rb'

=begin
assumes a network object will be passed in which supports the following API:
    network.getNodes(): returns all nodes in the network
    network.neighbors(id): returns all physical neighbours of node with the given id. 

XXX todo:
do we need @ids?
max_buffer should probably be set on a per-node basis
determine the number of replicas based on the adapt() method
i think we can replace the neighbour determination in initialize with neighbors_update?

need to write:
  adapt()
  digest()
  addNode() (done... not tested)

=end

class LMS
  def initialize(h, lambda_, network, max_buffer, max_failures)
    @hops, @lambda, @network, @max_buffer, @max_failures = h, lambda_, network, max_buffer, max_failures
    @nodes = @network.nodes
    @ids= {} # nids -> hash ids
    @LMSnodes= {}  #nids -> lMSNodes
    #per node
    @nodes.each{|key, value| 
      @ids[key] = hashId(key)
      o_neighbors = @network.neighbors(key)
      neighbors = o_neighbors
            
      (1...@hops).each{
        o_neighbors.each{|nid|
          neighbors += @network.neighbors(nid)
        }
        neighbors = neighbors.uniq #removes duplicates
        o_neighbors = neighbors
      }
      @LMSnodes[key] = LMSNode.new(@ids[key], max_buffer, neighbors)
    }
  end
  
  def addNode(x=nil, y=nil)
    new_id = @network.add(x,y)
    @ids[new_id] = hashID(new_id)
    @LMSnodes[new_id] = LMSnode.new(@ids[new_id], @max_buffer, nil)
    neighbors_update(@ids[new_id])
  end

  def hashId(nid) #Ask Bobby for the correct way of doing it
   d = Digest::MD5.hexdigest(nid)  
   return d.hash
  end
  
  def distance(k1, k2)
    w1 = k1 - (k2.modulo(2**@lambda))
    w2 = k2 - (k1.modulo(2**@lambda))
    if w1 < w2
      return w1
    else
      return w2
    end
  end
  
  def neighbors(nid)
   return @LMSnodes[nid].neighbors()
  end
  
  def neighbors_update(nid)
    o_neighbors = @network.neighbors(nid)
    neighbor_list = o_neighbors
            
    1...@hops.each{
      o_neighbors.each{|id|
        neighbor_list += @network.neighbors(id)
      }
      neighbor_list = neighbor_list.uniq #removes duplicates
      o_neighbors = neighbor_list
    }
    
    @LMSnodes[nid].set_neighbors(neighbor_list)
  end
  
  def local_minimum(nid, k)
    neighbors_update(nid) #update neighbors lazily... 
    neighbor = @LMSnodes[nid].neighbors
    id_min = nil
    min_dist = 2**@lambda #max distance possible
    neighbor.each{|id|
      dist = distance(@ids[id], k)
      if dist < min_dist
        min_dist = dist
        id_min = id
      end
    }
    return id_min
  end
  
  def random_walk(nid, probe)
    probe.walk()
    probe.add_to_path(nid)
    
    if probe.getLength() > 0
      neighbors_update(nid) #update neighbors lazily... might be computationally taxing
      neighbor = @LMSnodes[nid].neighbors
      random = neighbor[rand(neighbor.length)]
      return random_walk(random, probe)
    else
      return probe
    end
  end
  
  def deterministic_walk(nid, probe)
    probe.add_to_path(nid)
    v = local_minimum(nid, probe.getKey())
    if v == nid
      return nid
    else
      return deterministic_walk(v, probe)
    end
  end
  
  def put(initiator, item, k, n) #right now this function doesn't return anything... should it?
    1..n.each{
      walk_length = rand(91) + 10
      path = []
      probe = PUTProbe.new(item, initiator, k, walk_length, path, @max_failures)
      probe = random_walk(initiator, probe)
      last_node = probe.pop_last()
      found_minimum = deterministic_walk(last_node, probe)
      node = @LMSnodes[found_minimum]
      if node.bufferLength() >= @max_buffer || node.contains?(probe.getKey())
        probe.fail()
        probe.setLength(walk_length * 2)
        #duplication avoidance
        nid = probe.pop_last()
        probe = duplication_avoidance(nid, probe)
     
        if probe.getFailures() < 0
          next #don't even bother with this probe anymore....
        end 
        
      else
        #everything is good, lets add the item to the buffer
        node.add_to_buffer(probe.getKey(), item)
        puts "Message was stored at node " + node.id
      end
    }
  end
  
  def duplication_avoidance(nid, probe)
      walk_length = probe.getLength()
      
      while probe.getFailures() >= 0 do
        probe.setLength(walk_length)
        probe = random.walk(nid, probe)
        last_node = probe.pop_last()
        found_minimum = deterministic_walk(last_node, probe)
        node = @LMSnodes[found_minimum]
        if node.bufferLength() >= @max_buffer || node.contains?(probe.getKey())
          walk_length *= 2
          probe.fail()
          nid = probe.pop_last()
          next
        else
          node.add_to_buffer(probe.getKey(), probe.getItem())
          break
        end
      end
      return probe
  end
  
  def get(initiator, k)
      walk_length = rand(91) + 10
      path = []
      probe = Probe.new(initiator, k, walk_length, path)
      probe = random_walk(initiator, probe)
      last_node = probe.pop_last()
      found_minimum = deterministic_walk(last_node, probe)
      node = @LMSnodes[found_minimum]
   
      if node.contains?(probe.getKey())
        return node.get(probe.getKey())
      else
       #failsauce...
       return nil
      end
  end
end

class Probe
  def initialize(initiator, key, walk_length, path)
   @initiator, @key, @walk_length, @path = initiator, key, walk_length, path
  end
  
  def walk()
    @walk_length -=1
  end
  
  def setLenght(length)
    @walk_length = length
  end
  
  def getLength()
    return @walk_length
  end
  
  def getKey()
    return @key
  end
  
  def getInitiator()
    return @initiator
  end
  
  def getPath()
    return @path
  end
  
  def add_to_path(nid)
    @path.push(nid)
  end
  
  def pop_last()
    return @path.pop
  end
end

class PUTProbe < Probe
  def initialize(item, initiator, key, walk_length, path, failure_count)
    super(initiator, key, walk_length, path)
    @item, @failure_count = item, failure_count
  end
  
  def getItem()
    return @item
  end
  
  def getFailures()
    return @failure_count
  end
  
  def fail()
    @failure_count -= 1
  end
end

class LMSNode
  def initialize(id, neighbors)
    @id, @neighbors = id, neighbors
    @buffer = {} 
  end
  
  def id
    return @id
  end

  def neighbors()
    return @neighbors
  end
  
  def set_neighbors(neighbors)
    @neighbors = neighbors
  end
  
  def add_to_buffer(k, item)
    @buffer.store(k, item)
  end
  
  def contains?(k)
    return @buffer.key?(k)
  end
  
  def bufferLength()
    return @buffer.length
  end
  
  def get(k)
    return @buffer[k]
  end
end
