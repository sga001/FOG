require 'socket'
require 'location.rb'
require 'node.rb'

class Node
  def initialize(x,y)
    @x, @y = x, y
  end

  def x
    return @x
  end

  def y
    return @y
  end

  def x=(value)
    @x = value
  end 

  def y=(value)
    @y = value
  end

  def to_s
    return "[" + @x.to_s + "," + @y.to_s + "]"
  end

end

class UDS
  # UDS is a uniform disk simulator. it simulates the basic physical layer of a network. 
 
  def initialize(num_nodes, width, height, nbr_dist=1, distance_metric="euclidean")
    @width, @height, @nbr_dist, @distance_metric = width, height, nbr_dist, distance_metric
    # nodes is a hash of id:node pairs so that we can use different kinds of
    # ids if we ever want. for now the nodes are just given sequential ids.
    @nodes = {}
    (0...num_nodes).each{|n|
      @nodes[n] = Node.new(rand(width), rand(height))
    }
  end  
  
  def print_nodes
    if @nodes.length > 0
      puts @nodes
    else
      puts 'no nodes'
    end
  end

  def add(x=nil, y=nil)
    if x==nil or y == nil
      x, y = rand(width), rand(height)
    end 
    new_id = @nodes.size
    @nodes[new_id] = Node.new(x, y)
    new_id
  end
 
  def remove(nid)
    @nodes.delete(nid)  
  end
  
  def remove_all()
    @nodes.clear()
  end
  
  def distance(a, b)
    # compute the euclidean distance between nodes a and b. 
    Math.sqrt((@nodes[a].x - @nodes[b].x)**2 + (@nodes[a].y - @nodes[b].y)**2)
  end

 def neighbors(nid1, nid2=nil)
=begin
    if nid1 and nid2 are both passed in, return true or false depending on
    whether the two nodes are neighbours. if nid2=nil, return a list of all
    neighbours of nid1. 
=end

    if nid2:
      locA = @nodes[nid1]
      locB = @nodes[nid2]
      if distance(nid1, nid2) > @nbr_dist
        return false
      else
        return true
      end

    else # get all neighbours
      nbrs = []
      @nodes.each do |nid, node|
        if (nid1 != nid) and distance(nid1,nid) <= @nbr_dist
          nbrs.push(nid)
        end
      end
      nbrs
    end  
  end

  def move(nid, x, y)
    @nodes[nid].x = x
    @nodes[nid].y = y
  end
  
  def move_rel(nid, delx, dely)
    @nodes[nid].x += delx
    @nodes[nid].y += dely
  end
  
  def get_location(nid)
    return [@nodes[nid].x, @nodes[nid].y]
  end

end

# Running some lame tests :P
uds = UDS.new(5, 100, 100, 15, "euclidean")
n1 = uds.add(50, 50)
n2 = uds.add(50, 40)
n3 = uds.add(50, 25)
uds.print_nodes
puts uds.neighbors(n1, n2).to_s + "\n" # should print true
puts uds.neighbors(n1, n3).to_s + "\n" # should print false
puts uds.neighbors(n2, n3).to_s + "\n" # should print true
puts uds.get_location(n1) # should print [50, 50]
uds.move(n1, 45, 50)
puts uds.get_location(n1) # should print [45, 50]
uds.move_rel(n1, 5, 0)
puts uds.get_location(n1) # should print [50, 50]
uds.remove(n1) 
uds.remove(n2) 
uds.remove(n3) 
uds.remove_all()
uds.print_nodes # should print 'no nodes'
exit
