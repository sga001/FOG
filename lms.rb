require 'digest/md5'
require 'uds.rb'
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
  
end

class LMSNode
  def initialize(id, max_buffer, neighbors)
    @id, @max_buffer, @neighbors = id, max_buffer, neighbors
    
  end
  
  def neighbors()
    return @neighbors
  end
  
  def set_neighbors(neighbors)
    @neighbors = neighbors
  end
  
end