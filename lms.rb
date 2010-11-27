require 'digest/sha1'
require 'uds.rb'
require 'pp'
=begin
assumes a network object will be passed in which supports the following API:
    network.getNodes(): returns all nodes in the network
    network.neighbors(id): returns all physical neighbours of node with the given id. 

XXX todo:
handling of the network nodes? 
when and how to update neighbors
drop isolated nodes from the network/handle sparse network. 

do we need @ids?
 -> Yes, here's why: 
    Everything we do is mostly using NIDs (i.e. the ids returned from the
    physical network nodes)... except the distance
    comparison of a given key to the hash of a given node.... that's why we
    need the @ids... to find the hash of a given node    

max_buffer should probably be set on a per-node basis (hmmm how should we implement that?)
determine the number of replicas based on the adapt() method

need to write:
  adapt()
  digest()  (uhmmm... is this the bloomfilters stuff? do we REALLY need it... cause it sounds somewhat painful)

=end

$dup_calls = 0

class LMS
  def initialize(h, lambda_, network, max_failures)
    @hops, @lambda_, @network, @max_failures = h, lambda_, network, max_failures
    @nodes = @network.nodes
    @ids= {} # nids -> hash ids
    @LMSnodes= {}  #nids -> lMSNodes
    #per node
    @nodes.each{|key, value| 
      @ids[key] = hashId(key)
      @LMSnodes[key] = LMSNode.new(@ids[key], nil, nil)
      neighbors_update(key)
    }
  end
  
  def addNode(x=nil, y=nil, buffer_size=nil)
    new_id = @network.add(x,y)
    @ids[new_id] = hashID(new_id)
    # create a new node with no neighbours, and then call neighbors_update. 
    @LMSnodes[new_id] = LMSNode.new(@ids[new_id], nil, buffer_size)
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
      neighbor_list.delete(nid)
      o_neighbors = neighbor_list
    }
    if neighbor_list.include?(nid)
      raise "neighbor list of #{nid} should not include itself"
    end
    if neighbor_list.length == 0
      puts "Deleting disconnected node #{nid}"
      removeNode(nid)
    else
      @LMSnodes[nid].set_neighbors(neighbor_list)
    end
  end
  
  def removeNode(nid)
    @LMSnodes.delete(nid)
    @network.remove(nid)
    @ids.delete(nid)
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
  
  def put(initiator, item, data_key, replicas)
    hash = hashId(data_key)
    (1..replicas).each {|r| 
      puts "placing replica #{r}"
      walk_length = rand(50) + 10
      puts "initial walk_length: #{walk_length}"
      path = []
      probe = PUTProbe.new(item, initiator, hash, walk_length, path, @max_failures)
      success = false
      give_up = false
      while not success and not give_up
        puts "trying to store message..."
        probe = random_walk(initiator, probe)
        last_node = probe.pop_last()
        found_minimum = deterministic_walk(last_node, probe)
        node = @LMSnodes[found_minimum]
      
        if node.bufferFull || node.contains?(probe.getKey())
          probe.fail()
          if probe.getFailures >= @max_failures
            give_up = true
            puts "giving up on this replica, too many failures..."
          else
            probe.setLength(walk_length * 2)
            probe.clearPath()
          end
        else
          success = true
          #everything is good, lets add the item to the buffer
          node.add_to_buffer(probe.getKey(), item)
          puts "Replica #{r} from #{initiator} with key '#{data_key}' was stored at 
                node #{found_minimum.to_s} with #{probe.getFailures} failures"
          puts "Storage Path:"
          pp(probe.getPath())
        end
      end
    }
  end

  def get(initiator, k)
      k = hashId(k)
      walk_length = rand(10) + 5
      path = []
      probe = Probe.new(initiator, k, walk_length, path)
      probe = random_walk(initiator, probe)
      last_node = probe.pop_last()
      found_minimum = deterministic_walk(last_node, probe)
      node = @LMSnodes[found_minimum]
   
      return node, probe
#      if node.contains?(probe.getKey())
#        return node.get(probe.getKey())
#      else
       #failsauce...
#       return nil
#      end
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

  def clearPath
    @path.clear()
  end  

  def pop_last()
    return @path.pop
  end
end

class PUTProbe < Probe
  def initialize(item, initiator, key, walk_length, path, failure_count)
    super(initiator, key, walk_length, path)
    @item, @failure_count = item, 0
  end
  
  def getItem()
    return @item
  end
  
  def getFailures()
    return @failure_count
  end
  
  def fail()
    @failure_count += 1
  end
end

class LMSNode
  def initialize(id, neighbors, buffer_size=nil )
    @id, @neighbors = id, neighbors
    if buffer_size
        @max_buffer = buffer_size
    else
        @max_buffer = rand(20)
    end
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
    raise "Max buffer size exceeded" if @buffer.length >= @max_buffer
    @buffer.store(k, item)
  end
  
  def contains?(k)
    return @buffer.key?(k)
  end
  
  def bufferFull
    if @buffer.length >= @max_buffer
      return true
    else
      return false
    end
  end

  def bufferLength()
    return @buffer.length
  end
  
  def get(k)
    return @buffer[k]
  end
end
