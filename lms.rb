require 'digest/sha1'
require 'uds.rb'

=begin
assumes a network object will be passed in which supports the following API:
    network.getNodes(): returns all nodes in the network
    network.neighbors(id): returns all physical neighbours of node with the given id. 

XXX todo:
do we need @ids?
 -> Yes, here's why: 
    Everything we do is mostly using NIDs (i.e. the ids returned from the physical network nodes)... except the distance
    comparison of a given key to the hash of a given node.... that's why we need the @ids... to find the hash of a given node    


max_buffer should probably be set on a per-node basis (hmmm how should we implement that?)
determine the number of replicas based on the adapt() method
i think we can replace the neighbour determination in initialize with neighbors_update? - DONE

need to write:
  adapt()
  digest()  (uhmmm... is this the bloomfilters stuff? do we REALLY need it... cause it sounds somewhat painful)
  addNode() (done... FIXED A SMALL BUG YOU HAD :) )

=end

class LMS
  def initialize(h, lambda_, network, max_buffer, max_failures)
    @hops, @lambda_, @network, @max_buffer, @max_failures = h, lambda_, network, max_buffer, max_failures
    @nodes = @network.nodes
    @ids= {} # nids -> hash ids
    @LMSnodes= {}  #nids -> lMSNodes
    #per node
    @nodes.each{|key, value| 
      @ids[key] = hashId(key)
      @LMSnodes[key] = LMSNode.new(@ids[key], nil)
      neighbors_update(key)
    }
  end
  
  def addNode(x=nil, y=nil)
    new_id = @network.add(x,y)
    @ids[new_id] = hashID(new_id)
    @LMSnodes[new_id] = LMSnode.new(@ids[new_id], @max_buffer, nil)
    neighbors_update(new_id)
  end

  def hashId(nid)
   d = Digest::SHA1.hexdigest(nid.to_s).hex
   return d.modulo(2**@lambda_)
  end
  
  def distance(k1, k2)
    w1 = (k1 - k2).modulo(2**@lambda_)
    w2 = (k2 - k1).modulo(2**@lambda_)
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
    num = 1..@hops      
    num.each{
      o_neighbors.each{|id|
        neighbor_list += @network.neighbors(id)
      }
      neighbor_list = neighbor_list.uniq #removes duplicates
      o_neighbors = neighbor_list
    }
    
    @LMSnodes[nid].set_neighbors(neighbor_list)
  end
  
  def local_minimum(nid, k)
    #neighbors_update(nid) #update neighbors lazily... 
    neighbor = @LMSnodes[nid].neighbors
    id_min = nid
    min_dist = distance(@ids[nid], k)
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
      #neighbors_update(nid) #update neighbors lazily... might be computationally taxing
      neighbor = @LMSnodes[nid].neighbors
      if neighbor.length > 0
        random = neighbor[rand(neighbor.length)]
        return random_walk(random, probe)
      else
        probe.setLength(0)
        return probe
      end
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
  
  def put(initiator, item, k, n) #right now this fun tion doesn't return anything... should it?
   #puts "initiator = " + initiator.to_s #debug statement :P
    hk = hashId(k)
    num = 1..n
    num.each{
      walk_length = rand(50) + 10
      path = []
      probe = PUTProbe.new(item, initiator, hk, walk_length, path, @max_failures)
      probe = random_walk(initiator, probe)
      last_node = probe.pop_last()
      found_minimum = deterministic_walk(last_node, probe)
      node = @LMSnodes[found_minimum]
      if node.bufferLength() >= @max_buffer || node.contains?(probe.getKey())
        probe.fail()
        probe.setLength(walk_length * 2)
        #duplication avoidance
        nid = probe.pop_last()
        probe = duplication_avoidance(nid, probe, k)
     
        if probe.getFailures() < 0
          next #don't even bother with this probe anymore....
        end 
        
      else
        #everything is good, lets add the item to the buffer
        node.add_to_buffer(probe.getKey(), item)
        puts "Message " + k + " was stored at node " + found_minimum.to_s + " without failures"
      end
    }
  end
  
  def duplication_avoidance(nid, probe, k)
      walk_length = probe.getLength()
      
      while probe.getFailures() >= 0 do
        probe.setLength(walk_length)
        probe = random_walk(nid, probe)
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
          puts "Message " + k + " was stored at node " + found_minimum.to_s + " with " + (@max_failures - probe.getFailures()).to_s + " failures"
          break
        end
      end
      if probe.getFailures() <= 0
        puts "Message " + k + " was NOT store because of too many failures"
      end
      return probe
  end
  
  def get(initiator, k)
      k = hashId(k)
      walk_length = rand(50) + 10
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
  
  def setLength(length)
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