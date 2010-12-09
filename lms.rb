require 'digest/sha1'
require 'uds.rb'
require 'pp'

=begin
assumes a network object will be passed in which supports the following API:
    network.getNodes(): returns all nodes in the network
    network.neighbors(id): returns all physical neighbours of node with the given id. 

LMS handles replica determination, possibly based on dynamic criteria passed in
from individual publishing nodes.  
=end

class LMS
  # instatiated for each node. 
  def initialize(node, hops, lambda_, max_failures)
    @hops, @lambda, @max_failures = hops, lambda_, max_failures 

    # keep track of the parent node. (the externally facing one) 
    @node = node
    @hashID= computeHash(@node.realID)
    
    # max allowable failures in trying to store an item
    @max_failures = max_failures 
  end

  def computeHash(nid)
   d = Digest::SHA1.hexdigest(nid.to_s).hex
   return d.modulo(2**@lambda)
  end

  def hashID
    return @hashID
  end

  def distance(hash2)
    # computes distance between the current node, and the given key 
    w1 = (@hashID - hash2).modulo(2**@lambda)
    w2 = (hash2 - @hashID).modulo(2**@lambda)
    if w1 < w2
      return w1
    else
      return w2
    end
  end
  
  def neighborhood
    neighbors = @node.getNeighbors()
    h_hop_neighbors = neighbors #list of 1-hop neighbors, now we need to add all h-hop neighbors
    
    (1..@hops).each{
      neighbors.each{|node|
        h_hop_neighbors += node.getNeighbors()  
      }
      h_hop_neighbors = h_hop_neighbors.uniq #remove duplicates
      h_hop_neighbors.delete(@node)
      neighbors = h_hop_neighbors
    }
    return h_hop_neighbors
  end
  
  def local_minimum(k)
    # returns the node in the h-hop neighborhood whose hash forms a local minimum with the key to be stored
    min_node = @node
    min_dist = distance(k)
    neighbors = neighborhood()
    neighbors.each{|node|
      dist = node.getRouting().distance(k)
      if dist < min_dist
        min_dist = dist
        min_node = node
      end
    }
    return min_node
  end
  
  def random_walk(probe)
    neighbors = @node.getNeighbors()
    probe.walk()
    probe.add_to_path(@node.realID)
    if probe.getLength() > 0
      if neighbors.length > 0
        randomNode = neighbors[rand(neighbors.length)]
        return randomNode.getRouting().random_walk(probe)
      else
        probe.setLength(0)
        return @node, probe
      end
    else
      return @node, probe
    end
  end
  
  def deterministic_walk(probe)
    probe.add_to_path(@node.realID)
    min_node = local_minimum(probe.getKey())
    if min_node.realID == @node.realID
      return @node
    else
      return min_node.getRouting().deterministic_walk(probe)
    end
  end
  
  def put(key, item, replicas)
    hash = computeHash(key)
    initiator = @node.realID
    successes = 0
    (1..replicas).each {|r| 
      puts "placing replica #{r}"
      walk_length = rand(50) + 10
      puts "initial walk_length: #{walk_length}"
      path = []
      probe = PUTProbe.new(item, initiator, hash, walk_length, path, @max_failures)
      success = false
      give_up = false
      while not success and not give_up
        last_node, probe = random_walk(probe)
        probe.pop_last() #prevents adding id to path twice
        node = last_node.getRouting().deterministic_walk(probe)
      
        if node.bufferFull? or (node.containsKey?(key) and node.containsData?(item)) or node.distance(@node.x, @node.y) > item.radius
          probe.fail()
          if probe.getFailures >= @max_failures
            give_up = true
            puts "giving up on this replica, too many failures..."
          else
            probe.setLength(walk_length * 2)
            probe.clearPath()
          end        
        else
          #everything is good, lets add the item to the buffer
          success = true
          successes += 1
          node.bufferAdd(key, item)
          puts "Replica #{r} from #{initiator} with key '#{key}' was stored at" \
               + " node #{node.realID.to_s} with #{probe.getFailures} failures"
          puts "Storage Path: " + probe.getStringPath()
        end
      end
    }
    puts "#{successes} replicas were stored of Item #{key} (hash #{hash})\n"
    puts "------------------------"
  end

  def get(k)
      walk_length = rand(10) + 5
      path = []
      initiator = @nid
      probe = Probe.new(initiator, computeHash(k), walk_length, path)
      last_node, probe = random_walk(probe)
      probe.pop_last() #prevents adding id to path twice
      found_minimum = last_node.getRouting().deterministic_walk(probe)
      item = found_minimum.retrieve(k)
      return item, probe
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
  
  def finalNode()
    return @path.last
  end

  def getStringPath()
    s = ""
    @path.each{|p|
      s += p.to_s + "/"
    }
    return s.chop
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

