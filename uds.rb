#!/usr/bin/ruby

require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'
require 'pp'


class God
=begin
  The God class is all-seeing and all-knowing, and manages the existence and
  movement of Nodes. Nodes themselves are defined externally, and should 
  support arbitrary behaviour. 
=end

  def initialize(topology)
    @topology = topology
    # nodes is a hash of id:node pairs. Nodes are expected to expose x() and
    # y() methods. 
    @nodes = {}
    # god keeps time - make a note when the universe was created. 
    @time = 0 
    @maxID = 0
    @moveQueue = {}
  end
	
  def setNodeSettings(lbda, max_failures, hops, update_frequency = 50, type=FogNode, routing=LMS, buffer_size=1000)
  	@nodeType = type
  	@nodeRouting = routing
  	@nodeBufferSize = buffer_size
  	@nodeMaxFailures = max_failures
  	@nodeHops = hops
  	@nodeLambda_ = lbda
  	@nodeUpdateFrequency = update_frequency
  end

  def updateAllNeighbors()
    @nodes.each{|nid, node|
      updateNeighbors(nid)
    }
  end

  def updateNeighbors(nid)
    nbrList = @topology.allNeighbors(@nodes[nid], @nodes)   
    @nodes[nid].updateNeighbors(nbrList)
  end

  def nodes
    return @nodes
  end
  
  
  def getNode(nid)
    return @nodes[nid]
  end
  
  def addNode(x = rand(@topology.width), y = rand(@topology.height), speed = 5)
  	
  	node = @nodeType.new(@maxID, @nodeRouting, @nodeLambda_, @nodeHops, @NodeBufferSize, @nodeMaxFailures, x, y, speed=speed)
  	@nodes[@maxID] = node
  	@maxID+=1
  end
  
  def add(node)
    @nodes[node.realID] = node
  end

  def addAndUpdate(node)
    @nodes[node.realID] = node
    # update everyone's neighbours here, not just the new guy. 
    # XXX this should happen asynchronously. 
    updateAllNeighbors() 
  end
 
  def remove(nid)
    return @nodes.delete(nid)  
  end
  
  def remove_all()
    @nodes.clear()
  end
 
  def move(nid, x, y)
    @nodes[nid].x = x
    @nodes[nid].y = y
  end
  
  def moveRel(nid, delx, dely)
    @nodes[nid].x += delx
    @nodes[nid].y += dely
  end
  
  def location(nid)
    return [@nodes[nid].x, @nodes[nid].y]
  end
  
  def getTime()
  	return @time
  end
  
  def maxID()
  	return @maxID
  end

=begin
	Random Move: Uses Random Waypoint Model
=end 

  def discrete_move(nid) 
  	deltaX = @moveQueue[nid]['x'] - @nodes[nid].x
  	deltaY = @moveQueue[nid]['y'] - @nodes[nid].y
  	mx = deltaX
  	my = deltaY
  	if deltaX.abs > @nodes[nid].speed
  		mx = @nodes[nid].speed * (deltaX/(deltaX.abs))
  	end
  	
  	if deltaY.abs > @nodes[nid].speed
  		my = @nodes[nid].speed * (deltaY/(deltaY.abs))
  	end
  	
  	moveRel(nid, mx, my)
  	
  	if @nodes[nid].x == @moveQueue[nid]['x'] and @nodes[nid].y == @moveQueue[nid]['y']
  		@moveQueue.delete(nid)
  	end
  end
   
  def add_moveQueue(nid)
	xdest = rand(@topology.width)
	ydest = rand(@topology.height)
  	@moveQueue[nid] = {"nid"=> nid, "x"=>xdest, "y"=>ydest}
  	discrete_move(nid)
  end  
  
=begin 
	Join is an absolute probability (i.e. probability that a new node will join). 
	Move and Drop are per node probabilities (i.e. probability that any node
	in the universe will move or be dropped) Probabilities are in the range [0, 1000]
=end 
  def step(join = 5, drop= 1, move = 50)
	@moveQueue.each{|nid|
		if nid != nil
			discrete_move(nid[0])
		end
	}
	
	if drop != 0
		@nodes.each{|n|
			prob_drop = rand(1000)
			if prob_drop < drop
				@moveQueue.delete(n[0])
				@nodes.delete(n[0])
			end
		}
	end
  	
  	prob_join = rand(1000)
  	if prob_join < join
  		addNode(speed = rand(5))
  	end
  	
  	if move != 0 
	  	@nodes.each{|n|
	  		prob_move = rand(1000)
	  		if prob_move < move
	  			add_moveQueue(n[0])
		  	end
	  	}
	end
  	
  	@time += 1
  	if @time % @nodeUpdateFrequency == 0
  		updateAllNeighbors()
  	end
  end
end

class UDS
=begin UDS stands for uniform disk simulator It simulates the basic broadcast
  # environment of a physical layer of a network with the specified size and
  # distance metrix
=end 

  def initialize(width, height, nbr_dist=1, distance_metric="euclidean")
    @width, @height, @nbr_dist, @distance_metric = width, height, nbr_dist, distance_metric
  end  
  
  def width
    return @width
  end

  def height
    return @height
  end

  def distance(n1, n2)
    # compute the euclidean distance between nodes a and b
    return Math.sqrt((n1.x - n2.x)**2 + (n1.y - n2.y)**2)
  end

 def neighbors?(n1, n2)
    # return true or false depending on whether the two nodes are neighbours
    if distance(n1, n2) > @nbr_dist
      return false
    else
      return true
    end
  end

 def allNeighbors(thisnode, allnodes)
    nbrs = []
    allnodes.each{|nid, node|
      if (thisnode != node) and distance(thisnode,node) <= @nbr_dist
        nbrs.push(node)
      end
    }
    return nbrs
 end
end
