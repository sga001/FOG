require 'digest/md5'
#require 'uds.rb'
class LMS
  def initialize(h, lambda, network, max_buffer, max_failures)
    @hops, @lambda, @network, @max_buffer, @max_failures = h, lambda, network, max_buffer, max_failures
    @nodes = @network.getNodes()
    @ids= {} # nids -> hash ids
    @LMSnodes= {}  #nids -> lMSNodes
    
    #per node
    @nodes.each{|key, value| 
      @ids[key] = hashId(key)
      o_neighbors = @network.getNeighbors(key)
      neighbors = o_neighbors
            
      1...@hops.each{
        o_neighbors.each{|nid|
          neighbors += @network.getNeighbors(nid)
        }
        neighbors = neighbors.uniq #removes duplicates
        o_neighbors = neighbors
      }
      @LMSnodes[key] = LMSNode.new(@ids[key], max_buffer, neighbors)
    }
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
    o_neighbors = @network.getNeighbors(nid)
    neighbor_list = o_neighbors
            
    1...@hops.each{
      o_neighbors.each{|id|
        neighbor_list += @network.getNeighbors(id)
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
    return @id_min
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
  
  def put(initiator, item, k, n)
    # TODO
  end
  
end

class Probe
  def initialize(initiator, key, walk_length, path)
   @initiator, @key, @walk_length, @path = initiator, key, walk_length, path
  end
  
  def walk()
    @walk_length -=1
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
end

class LMSNode
  def initialize(id, neighbors)
    @id, @neighbors = id, neighbors
    @buffer = [] 
  end
  
  def neighbors()
    return @neighbors
  end
  
  def set_neighbors(neighbors)
    @neighbors = neighbors
  end
  
  def bufferLength()
    return @buffer.length
  end
end
