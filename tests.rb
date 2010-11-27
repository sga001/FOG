require 'uds.rb'
require 'lms.rb'
# require 'pubsub.rb'

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

# Play around with all of these numbers to see the difference... is crazy :p but it kinda makes sense
uds = UDS.new(100, 300, 300, 50, "euclidean") #gotta initialize uds again since we just removed all the nodes :p


hops = 5  # CHANGE THIS AND SEE THE DIFFERENCE :P
lambda_ = 256
network = uds
max_buffer = 10
max_failures = 5
lms = LMS.new(hops, lambda_, uds, max_buffer, max_failures)

nature_msg = "punk rock kittens"
event_msg = "chinese festival of dragons"
review_msg = "the chicken today is terrible"

# the key of the put request is like the tag. 

# XXX TODO need to pull out the LMS node IDs so we can choose IDs for the (EASY..... just call uds.nodes() :P)
# 'initiator' argumentof put/get

ids = uds.nodes
first=  ids.keys[0]
second = ids.keys[1]



lms.put(first, nature_msg, 'nature', 10)
lms.put(first, event_msg, 'event', 10)
lms.put(second, review_msg, 'review', 10)  #notice that I'm inserting it with node 2nd

puts " ---- GETS START HERE ----"
puts lms.get(first, 'event')
puts lms.get(second, 'event')
puts lms.get(first, 'review')
puts lms.get(second, 'review')
puts lms.get(first, 'nature')
puts lms.get(second, 'nature')
