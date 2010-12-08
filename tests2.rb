require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'

topology = UDS.new(400, 400, 50)
universe = God.new(topology)

tags = ["events", "system", "reviews", "happy", "blah", "animals"]
lambda_ = 256
hops = 2
num_nodes = 10



(1..num_nodes).each{|id|
  x = rand(width)
  y = rand(height)
  subscriptions = tags[rand(tags.length)] 
  universe.add(FogNode.new(id, routing=LMS, lambda_, hops, buffer_size = rand(20), max_failures = 5, x, y))
}


