require 'socket'
require 'location.rb'
require 'node.rb'
class UDS
 
  def initialize(num_nodes, width, height, nbr_dist=1, distance_metric="euclidean")
    @num_nodes, @width, @height, @nbr_dist, @distance_metric = num_nodes, width, height, nbr_dist, distance_metric
    @id = 0
    @nodes = {} #mapping of nids -> locations
    @pids = {} #mapping of nids -> pids (in order to kill the process)
    @host = "127.0.0.1"
    @port = 12000
    num = 1..num_nodes
    num.each{|n|
      loc = Location.new(rand(width), rand(height))
      pid = fork do 
        Signal.trap("QUIT") { puts "Node at location " + loc.to_s() + " removed\n"; exit }
        node = Node.new(@host, @port+@id) 
        node.start()
      end  
      @nodes[@id] = loc
      @pids[@id] = pid
      @id +=1
      Process.detach(pid)
    }
  end
  
  
  def add(x=nil, y=nil)
    if x==nil and y == nil
      loc = Location.new(rand(@width), rand(@height))
    else
      loc = Location.new(x, y)
    end 
    @num_nodes += 1
    pid= fork do
      Signal.trap("QUIT") { puts "Node at location " + loc.to_s() + " removed\n"; exit }
      node = Node.new(@host, @port + @num_nodes)
      node.start()
    end
    @nodes[@id] = loc
    @pids[@id] = pid
    @id += 1
    Process.detach(pid)
    return @id - 1 
  end
 
  def remove(nid)
     if @pids.has_key?(nid)
      Process.kill("QUIT", @pids[nid])
      @pids.delete(nid)
      @nodes.delete(nid)
    end
    @num_nodes-=1
  end
  
  def remove_all()
    @pids.each{|id, pid| Process.kill("QUIT", pid)}
    @pids.clear()
    @nodes.clear()
  end
  
  
  def neighbors(nid1, nid2)
    locA = @nodes[nid1]
    locB = @nodes[nid2]
    distance = locA.distance(locB)
    if distance > @nbr_dist
      return false
    else
      return true
    end
  end
  
  def move(nid, x, y)
    @nodes[nid] = Location.new(x, y)
  end
  
  def move_rel(nid, delx, dely)
    loc = @nodes[nid]
    x = loc.getX() + delx
    y = loc.getY() + dely
    @nodes[nid] = Location.new(x, y)
  end
  
  def get_location(nid)
    return @nodes[nid]
  end
end

# Running some lame tests :P
uds = UDS.new(5, 100, 100, 15, "euclidean")
n1 = uds.add(50, 50)
n2 = uds.add(50, 40)
n3 = uds.add(50, 25)
sleep(5)
puts uds.neighbors(n1, n2).to_s + "\n" # should print true
puts uds.neighbors(n1, n3).to_s + "\n" # should print false
puts uds.neighbors(n2, n3).to_s + "\n" # should print true
sleep(5)
puts uds.get_location(n1) # should print [50, 50]
sleep(2)
uds.move(n1, 45, 50)
puts uds.get_location(n1) # should print [45, 50]
sleep(2)
uds.move_rel(n1, 5, 0)
puts uds.get_location(n1) # should print [50, 50]
sleep(10)
uds.remove(n1) # should print Node at location [50, 50] removed
sleep(2)
uds.remove(n2) # should print Node at location [50, 40] removed
sleep(2)
uds.remove(n3) # should print Node at location [50, 25] removed
sleep(2)
uds.remove_all()
exit