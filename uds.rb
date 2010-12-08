#!/usr/bin/ruby

class God
=begin
  The God class is all-seeing and all-knowing, and manages the existence and
  movement of Nodes themselves are defined externally, and should 
  support arbitrary behaviour
=end

  def initialize(topology)
    @topology = topology
    # nodes is a hash of id:node pairs Nodes are expected to expose x() and
    # y() methods
    @nodes = {}
    # God will periodically update the physical neighbors of each node
    @physical_neighbors = {}
  end

  def updateAllNeighbors()
    @nodes.each{|nid|
      nrbList = @topology.allNeighbors(nid, @nodes)
      @physical_neighbors[nid] = nbrList
    }
  end

  def updateNeighbors(nid)
    @physical_neighbors[nid] = @topology.allNeighbors(nid, @nodes)
  end

  def nodes
    return @nodes
  end
  
  def getNeighbors(nid)
    return @physical_neighbors[nid]
  end
  
  def getNode(nid)
    return @nodes[nid]
  end
  
  def add(nid, node)
    @nodes[nid] = node
    updateNeighbors(nid) 
  end
 
  def remove(nid)
    @nodes.delete(nid)  
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
    Math.sqrt((n1.x - n2.x)**2 + (n1.y - n2.y)**2)
  end

 def neighbors?(n1, n2)
    # return true or false depending on whether the two nodes are neighbours
    if distance(n1, n2) > @nbr_dist
      return false
    else
      return true
    end
  end

 def allNeighbors(thisnid, allnodes)
    nbrs = []
    allnodes.each do |nid, node|
      if (thisnid != nid) and distance(thisnid,nid) <= @nbr_dist
        nbrs.push(nid)
      end
    end
    return nbrs
 end
end