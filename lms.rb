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
  def initialize(nid, hops, lambda_, max_failures, god)
    @hops, @lambda, @max_failures = hops, lambda_, max_failures 

    # keep track of the parent node's ID. (the externally facing one) 
    @nid = nid
    @hashID= computeHash(nid)

    # max allowable failures in trying to store an item
    @max_failures = max_failures 
    
    # Have god as a reference
    @god = god

    # initialize neighbours
    @neighbors = []
    neighbors_update()
  end

  def computeHash(nid)
   d = Digest::SHA1.hexdigest(nid.to_s).hex
   return d.modulo(2**@lambda)
  end

  def hashID
    return @hashID
  end

  def neighbors_update()
    o_neighbors = @god.getNeighbors(nid)
    neighbor_list = o_neighbors
    num = 1..@hops      
    num.each{
      o_neighbors.each{|id|
        neighbor_list += @god.getNeighbors(id)
      }
      neighbor_list = neighbor_list.uniq #removes duplicates
      neighbor_list.delete(nid)
      o_neighbors = neighbor_list
    }
    if neighbor_list.include?(nid)
      raise "neighbor list of #{nid} should not include itself"
    end
   
    @neighbors = neighbor_list
  end

  def distance(hash1, hash2)
    # computes distance between two hashes-- hashes can be nodes or data tags. 
    w1 = (hash1 - hash2).modulo(2**@lambda)
    w2 = (hash2 - hash1).modulo(2**@lambda)
    if w1 < w2
      return w1
    else
      return w2
    end
  end
  
  def neighbors()
    return @neighbors
  end

  def local_minimum(hashID, k)
    # returns the node whose hash forms a local minimum with the key to be
    # stored. 
    id_min = nid
    min_dist = distance(hashID, k)
    @neighbors.each{|id|
      dist = distance(hashID, k)
      if dist < min_dist
        min_dist = dist
        id_min = id
      end
    }
    return id_min
  end
  
  def random_walk(hashID, probe)
    probe.walk()
    probe.add_to_path(hashID)
    if probe.getLength() > 0
      if @neighbors.length > 0
        random = @neighbors[rand(@neighbors.length)]
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
  
  def put(item, data_key, replicas)
    hash = hashId(data_key)
    initiator = @nid
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
        probe = random_walk(initiator, probe)
        last_node = probe.pop_last()
        found_minimum = deterministic_walk(last_node, probe)
        # problem is here..
        node = @god.getNode(found_minimum)
      
        if node.bufferFull? || node.contains?(probe.getKey())
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
          node.bufferAdd(probe.getKey(), item)
          puts "Replica #{r} from #{initiator} with key '#{data_key}' was stored at" \
               + " node #{found_minimum.to_s} with #{probe.getFailures} failures"
          puts "Storage Path: " + probe.getStringPath()
        end
      end
    }
    puts "#{successes} replicas were stored of Item #{data_key} (hash #{hash})\n"
    puts "------------------------"
  end

  def get(k)
      k = hashId(k)
      walk_length = rand(10) + 5
      path = []
      initiator = @nid
      probe = Probe.new(initiator, k, walk_length, path)
      probe = random_walk(initiator, probe)
      last_node = probe.pop_last()
      found_minimum = deterministic_walk(last_node, probe)
      node = @god.getNode(found_minimum)
   
      return node, probe
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

