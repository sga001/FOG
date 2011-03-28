=begin
	this module acts like a black box message for passing between the node
	and its environment. by implementing it as a module, it simply helps to
	make the code more modularized. we could define a different module with
	different behaviour for getting the neighbors.  

=end

module Comms
	# defines a simulated communications ability for the nodes.
	# needs to talk to the one simulator, and every node.
	# usage: in an experiment, once a simulator s is defined:
	# class Node
	#	extend Comms
	# end
	# # commSetup is a class method
	# Node.commSetup(s)
	# n = Node.new
	# n.getNeighbors()

	def commSetup(s)
		@sim = s
		include CommsMethods
	end
end

module CommsMethods
	# defines methods that Nodes will use to communicate with the outside
	# world. This module gets included by the Comms module, so these become
	# instance methods. 
	def getNeighbors()
		@sim.calculateNbrs(@ID)
	end
end

module UDSTopology
	# defines behaviour specific to a uniform disc topology (2D euclidean
	# space with wrap-around behaviour). Is also demonstrative of the methods
	# that another topology module would need to define to function with the
	# Simulator 

	def dimensions(width, height)
		# initialization function
		@width = width
		@height = height
		# keep track of which locations are occupied. optimization.  
		@occupied = Array.new(width) {Array.new(height)}
	end
	
	def distance(n1, n2)
		# compute the euclidean distance between two node objects (noting that
		# an object at (0,0) and (0,width-1) are neighbours in a space with
		# wrap-around behaviour). 
		xDist = (n1.x - n2.x) % @width
		yDist = (n1.y - n2.y) % @height
		return Math.sqrt(xDist**2 + yDist**2)
	end

	def moveNode(nodeID, coords)
		# move nodeID to a specific location specified by a tuple (in this
		# case, (x,y), ensuring the location remains within the bounds of the
		# defined topology. 	
		oldX = @nodes[nodeID].x
		oldY = @nodes[nodeID].y
		newX = coords[0] % @width
		newY = coords[1] % @height
		if @occupied[newX][newY]
			return false
		else
			@occupied[oldX][oldY] = false
			@nodes[nodeID].x = newX
			@nodes[nodeID].y = newY
			@occupied[newX][newY] = true
		end
		return true
	end

	def addNode()
		# pick randomly from the set of empty locations. alternatively, we
		# could pick a random spot until we find one that's unoccupied. 
		# XXX arguably, nodes should enter from the edges of the space only.
		# however, there are various reasons why this might not be the case--
		# getting out of a car, turning on a device, etc. 
		available = emptySpots()
		if available.empty?
			return false
		else
			loc = available[rand(available.length)]
			@occupied[loc[0]][loc[1]] = true
			n = Node.new(loc[0], loc[1])
			@nodes[n.nid] = n
		end
		return n
	end

	def removeNode(nodeID)
		# delete the node and update its location to un-occupied. return true
		# for success, false for failure
		n = @nodes[nodeID]
		unless n == nil 
			@occupied[n.x][n.y] = false
			@nodes.delete(nodeID)		
			return true
		end
		return false
	end

	def validOneStepLocations(nodeID)
		# returns valid locations (in absolute terms) that the node may move to
		# in one step, taking into account topology and removing any occupied
		# spots
		
		# here we allow a node to move to any of the 8 spots immediately
		# adjacent, including on the diagonal.
		valid = []
		x = @nodes[nodeID].x
		y = @nodes[nodeID].y
		(-1,0,1).each{|relX|
			(-1,0,1).each{|relY|
				valid.push([x+relX, y+relY]) unless @occupied[x+relX][y+relY]
			}
		} return valid
	end

	def emptySpots()
		empty = []
		# fancy-pants ruby block notation... <3.  
		@occupied.each_index{|x| @occupied.each_index{|y| empty << [x,y] if 
							@occupied[x][y] == false} }
		return empty
	end
end

class Simulator
	
	def initialize()
		@nodes = [] # [{nodeID => nodeObject}, {...}, ...]
		@nodeData = [] # [{nodeID => currentNeighbors}, {...}, ...] 
		@time = 0

		# there are some basic supported events for every simulator.
		# Additionally, protocol-specific behaviour can be defined in a module
		# and then included in a specific simulator. When that happens, the
		# protocol-specific event module implements both a method for their
		# event(s), and registers their event by adding it to the
		# supportedEvents hash. It is worth noting that certain NON-event
		# functionality is supported as well, such as retrieving a node, or
		# calculating neighbours, etc. Non-events are for inspection only, they
		# do not increase the time or change the state of the system
		@supportedEvents = {'addNode' => :addNode,
							'addNodes' => :addNodes, 
							'removeNode' => :removeNode,
							'removeNodes' => :removeNodes,
							'advanceState' => :advanceState,
						} # {eventName => :functionReference, ...}
	end	
	attr_accessor :time

	def calculatePhysicalNbrs(nodeID)
		# iterate over all nodes and if the distance is within the broadcast
		# radius of the node, then it is a physical neighbour. O(n).
		thisNode = @nodes[nodeID]
		nbrs = []
		@nodes.each{|otherID, otherNode|{
			if ((thisNode != otherNode) and 
				distance(thisNode, otherNode) < thisNode.broadcastRadius)
				nbrs.push(otherID)
			end
		}
		return nbrs
	end 

	def calculateNeighbors(nodeID)
		# calculate the neighbors of a node given the number of hops it has
		# indicated as its local neighborhood.  
		nbrs = calculatePhysicalNeighbors(nodeID) 
		if @nodes[nodeID].hops = 1 then return nbrs

		# keep track of which neighbours we've already calculated so we don't
		# duplicate efforts. 
		alreadyCalculated = []
		(1..@nodes[nodeID].hops).times {
			moreNbrs = nbrs
			nbrs.each{|nbr|
				unless alreadyCalculated.find(nbr)  
					moreNbrs += calculatePhysicalNeighbors(nbr)
					alreadyCalculated.push(nbr) 
				end
			} 
			nbrs += moreNbrs
		}
		return nbrs.uniq
	end

	def registerEvent(eventName)
		@supportedEvents[eventName] = :eventName
	end


	def event(eventName, eventArgs)
		# everything we ask the sim to do can get passed through this method,
		# which will log the actions, increase the time step, and do other
		# management tasks as needed. 
			
		@time += 1
		send(@supportedEvents[eventName], eventArgs) unless not	
			supportedEvents.index(eventName)  

		# do some fancy logging here?
	end


	############## all methods that follow are private ############
	###############################################################
	private 

	def getNode(nodeID)
		return @nodes[nodeID]
	end

	def stepNodeRandom(nodeID)
		# modes the node one step in a random direction. return true unless
		# there are no open neighbouring positions, in which case returns
		# false. 
		valid = validOneStepLocations()
		if valid.empty?
			return false
		else
			new = valid[rand(valid.length)]
			moveNode(nodeID, [new[0], new[1]]	
		end
		return true
	end

	def stepNodeWithPurpose()
		# modes the node one step in a semi-random fashion but with an overall
		# long term destination (not sure best way to do this quite yet)
	end

	def addNodes(num)
		(1..num).times{
			addNode()
		}
	end

	def removeNodes(num)
		# delete one or more nodes selected at random
		(0..num).times {
			nid = @nodes.keys()[rand(@nodes.length)]
			removeNode(nid)	
		}
	end

	def moveNodes(num)
		alreadyMoved = []
		while num > 0 {
			nid = @nodes.keys()[rand(@nodes.length)]
			unless alreadyMoved.include? nid
				stepNodeRandom(nid) 
				num -= 1
			end
		}
	end


	def advanceState(numNew, numKill, percentMove)
		# advances the state of the system by one slice of time. the
		# system state consists of current nodes' positions, new nodes being
		# added, and existing nodes being killed off. 
		
		# note: if a node is going to be killed there's no point moving it. if
		# a node is going to be added there's also no point moving it (since
		# its initial location is random anyway). main design decision is
		# whether to add new nodes/kill off old nodes before or after the
		# existing nodes move. since the movement is random, i believe these
		# are equivalent-- that is, it doesn't matter. 

		removeNodes(numKill) unless numKill == 0
		addNodes(numNew) unless numNew == 0
		numMove = (@nodes.length * percentMove).round 
		moveNodes(numMove) unless numMove == 0
	end
		

end

############ experiment ###########
sim = Simulator.new
# by including the UDSTopology module we build into the simulator several new
# methods and instance variables, including width and height, which we can then
# initialize by calling the dimensions() method, also included as part of the
# UDSTopology module.  
sim.include LMSEvents
sim.include UDSTopology
sim.dimensions(width, height)

class Node
	extend Comms
	include LMS
end 
Node.commSetup(sim)
Node.LMSSetup(...)

sim.event('addNodes', 1000)
sim.event('advanceState', numAdd=10, numKill=20, percentMove=50)
sim.event('put', ['events', 'the bon jovi concert was good', 50])



