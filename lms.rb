require 'digest/sha1'
require 'pp'

=begin
assumes a network object will be passed in which supports the following API:
    network.getNodes(): returns all nodes in the network
    network.neighbors(id): returns all physical neighbours of node with the given id. 

LMS handles replica determination, possibly based on dynamic criteria passed in
from individual publishing nodes.  
=end

module LMSEvents
	# gets included in the simulator
	# sim.include LMSEvents
	# the include call will invoke self.included() and register the events with
	# the simulator. 
	
	def self.included(obj)
			supported = obj.instance_variable_get(:@supportedEvents)
			supported['LMSPut'] = :LMSPut
			supported['LMSGet'] = :LMSGet
			obj.instance_variable_set(:@supportedEvents, supported)
	end

	def LMSPut(nodeID, tag, message, replicas)
		@nodes[nodeID].put(tag, message, replicas)
	end

	def LMSGet(tag)
		@nodes[nodeID].get(tag)
	end
end

module LMS
	@@hops = nil
	@@lambda = nil
	@@max_failures = nil
	@@randomWalkRange = nil
	@@randomWalkMin = nil

	def self.setup(hops, lambda_, max_failures, randWalkRange, randWalkMin)
		# set up some class-level variables to specify parameters of this LMS
		# 'install'. call this after including the module to initialize.  
		
		# how many hops should the node consider in its LMS
		# neighborhood?
		@@hops = hops 
		
		# the size of the ID space is 2**lambda
		@@lambda = lambda_ 
		
		# max allowable failures in trying to store an item
		@@max_failures = max_failures 

		# random walk lengths - range and start value
		@@randomWalkRange = randWalkRange
		@@randomWalkMin = randWalkMin

		@@hash_functions = [1, 2, 3, 4, 5]
	end
	
	# this will get called via super from the including class' initialize
	# method (by design)
	def initialize()
		puts "calling initialize of LMS"
		@hashID= computeHash(@nid)
		super
	end
	attr_accessor :hashID

	def randWalkLength()
		return rand(@@randomWalkRange) + @@randomWalkMin
	end

	def put(key, item, replicas)
		initiator = @nid
		successes = 0.0
		stats = {}
		(1..replicas).each {|r| 
			hash_string = @@hash_functions[rand(@@hash_functions.length)].to_s
			hash = computeHash(key + hash_string)
			walk_length = randWalkLength()
			path = []
			probe = PUTProbe.new(item, initiator, hash, walk_length, path, 
								 @@max_failures)
			success = false
			give_up = false
			while not success and not give_up
				last_node, probe = random_walk(probe)
				#prevent adding id to path twice        
				probe.pop_last() 
				node = last_node.deterministic_walk(probe)

				if node.bufferFull? or (node.containsKey?(key) and 
										node.containsData?(item)) 
					probe.fail()
					if probe.getFailures >= @@max_failures
						give_up = true
					else
						probe.setLength(walk_length * 2)
						probe.clearPath()
						next
					end        
				else
					success = true
					successes += 1.0
					node.bufferAdd(key, item)
				end

				# log information about successes and failures, where the item was
				# deposited, and the path it took. 
				stats[r] = {'initiator' => initiator, 
							'failures' => probe.getFailures, 
							'success' => success, 'path' => probe.getStringPath, 
							'location'=> @nid.to_s
						}
			end
		}

		# recall = TP/TP+FN. in this case a FN (false negative) is when put()
		# fails (when, ideally, it shouldn't). since the number of replicas
		# requested is the total number of tries, TP+FN = replicas. the ideal
		# recall for a put() would be 1.0.
		stats['replicas'] = replicas
		stats['successes'] = successes
		recall = successes/replicas
		return recall, stats
	end

	def get(k)
		walk_length = randWalkLength()
		path = []
		initiator = @nid
		hash = computeHash(k + @@hash_functions[rand(@@hash_functions.length)].to_s)
		probe = Probe.new(initiator, hash, walk_length, path)
		last_node, probe = random_walk(probe)
		probe.pop_last() #prevents adding id to path twice
		found_minimum = last_node.deterministic_walk(probe)
		# note that 'item' will be null if this LM does not have the item. 
		item = found_minimum.retrieve(k)
		# return probe so can print stats about path. 
		return item, probe
	end

	def managedGet(k, max=100)
		# repeats the get request until it succeeds (or gets to 'max') and keeps
		# statistics on failures
		item_found = false
		tries = 0
		stats = {}
		until item_found or tries == max
			item_found, probe_data = get(k)
			cost = probe_data.getPath.length
			tries += 1
		end
		# recall = TP/(TP+FN). a 'FN' (false negative) is when get() falsely
		# returns nil. in this case the loop stops at TP=1 and thus tries is equal
		# to TP+FN. 
		if item_found
			recall = 1.0/(tries)
			stats["success"] = true
		else
			recall = 0
			stats["success"] = false
		end
		stats["tries"] = tries
		stats["max_tries"] = max
		return item_found, recall, stats
	end

	def computeHash(nid)
		d = Digest::SHA1.hexdigest(nid.to_s).hex
		return d.modulo(2**@@lambda)
	end

	def keyDistance(hash2)
		# computes distance between the current node, and the given key 
		w1 = (@hashID - hash2).modulo(2**@@lambda)
		w2 = (hash2 - @hashID).modulo(2**@@lambda)
		if w1 < w2
			return w1
		else
			return w2
		end
	end

	def neighborhood
		nbrs = getPhysicalNbrs()
		return nbrs if @@hops == 1 

		# keep track of which neighbours we've already calculated so we don't
		# duplicate efforts. 
		alreadyCalculated = []
		@@hops.times{
			moreNbrs = nbrs
			nbrs.each{|nbr|
				unless alreadyCalculated.include? nbr   
					moreNbrs += getPhysicalNbrs(nbr)
					alreadyCalculated.push(nbr) 
				end
			} 
			nbrs += moreNbrs
		}
		nbrs.delete(@nid)	
		return nbrs.uniq
	end

	def local_minimum(k)
		# returns the node in the h-hop neighborhood whose hash forms a local
		# minimum with the key to be stored
		min_node = @node
		min_dist = keyDistance(k)
		neighbors = neighborhood()
		neighbors.each{|node|
			dist = node.keyDistance(k)
			if dist < min_dist
				min_dist = dist
				min_node = node
			end
		}
		return min_node
	end

	def random_walk(probe)
		neighbors = getNeighbors()
		probe.walk()
		probe.add_to_path(@nid)
		if probe.getLength() > 0
			if neighbors.length > 0
				randomNode = neighbors[rand(neighbors.length)]
				return randomNode.random_walk(probe)
			else
				probe.setLength(0)
				return self, probe
			end
		else
			return self, probe
		end
	end

	def deterministic_walk(probe)
		probe.add_to_path(@nid)
		# local minima for this item's key
		min_node = local_minimum(probe.getKey())
		if min_node.nid == @nid
			return self
		else
			return min_node.deterministic_walk(probe)
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

