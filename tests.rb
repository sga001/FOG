require 'uds.rb'
require 'lms.rb'
require 'pp'

# require 'pubsub.rb'

# Test the UDS layer
=begin
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
=end

# Set up the physical network
# Play around with all of these numbers to see the difference... is crazy :p
# but it kinda makes sense
# initialize uds again since we just removed all the nodes :p
num_nodes = 400
width = 100
height = 100
nbr_dist = 5
distance_metric = 'euclidean'
uds = UDS.new(num_nodes, width, height, nbr_dist, distance_metric) 

# Set up the LMS routing layer
hops = 2  # CHANGE THIS AND SEE THE DIFFERENCE :P
lambda_ = 256
network = uds
max_failures = 5
lms = LMS.new(hops, lambda_, uds, max_failures)

# define some messages 
nature_msg = "punk rock kittens"
event_msg = "chinese festival of dragons"
review_msg = "the chicken today is terrible"

# pull out the LMS node IDs so we can choose IDs for the 'initiator' argument
# of put/get
ids = uds.nodes
n1 =  ids.keys[0]
n2 = ids.keys[num_nodes/2]
# if there are too many replicas, i think it fails because there's not enough local minima
replicas = 2

lms.put(n1, nature_msg, 'nature', 2)
lms.put(n1, event_msg, 'event', 2)
lms.put(n2, review_msg, 'review', 2)  #notice that I'm inserting it with node 2nd

puts " ---- GETS START HERE ----"
puts "Node #{n1} retrieving its OWN item with tag 'event'" 
node, probe = lms.get(n1, 'event')
p "Probe returned local minimum #{node.getRealId()} with path #{probe.getStringPath}"

puts "Node #{n2} retrieving items with tag 'event'" 
node, probe = lms.get(n2, 'event')
p "Probe returned local minimum #{node.getRealId()} with path #{probe.getStringPath}"

puts "Node #{n1} retrieving items with tag 'review'" 
node, probe = lms.get(n1, 'review')
puts "Probe returned local minimum #{node.id} from #{probe.finalNode} via path #{probe.getPath}

"

puts "Node #{n2} retrieving its OWN item with tag 'review'" 
node, probe = lms.get(n2, 'review')
puts "Probe returned local minimum #{node.id} from #{probe.finalNode} via path #{probe.getPath}

"

puts "Node #{n1} retrieving its OWN items with tag 'nature'" 
node, probe = lms.get(n1, 'nature')
puts "Probe returned local minimum #{node.id} from #{probe.finalNode} via path #{probe.getPath}

"

puts "Node #{n2} retrieving items with tag 'nature'" 
node, probe = lms.get(n2, 'nature')
puts "Probe returned local minimum #{node.id} from #{probe.finalNode} via path #{probe.getPath}

"

