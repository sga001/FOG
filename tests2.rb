require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'


topology = UDS.new(width=400, height=400, nbr_dist=50)
universe = God.new(topology)

tags = ["events", "system", "reviews", "happy", "blah", "animals"]
lambda_ = 256
hops = 2



(1..num_nodes).each{|id|
  x = rand(width)
  y = rand(height)
  subscriptions = tags[rand(tags.length)] 
  universe.add(FogNode.new(id, x, y, routing=LMS, lambda_, hops, 
                buffer_size = rand(20), max_failures = 5))
}


