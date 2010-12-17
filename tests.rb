require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'
require 'pp'
=begin
Time to do complicated tests involving: MOVING AROUND, WEIRD TOPOLOGIES, ETC.
I also did not implement the TIME DISCRIMINATOR STUFF and therefore expiry doesn't work.
=end

width = 200
height = 200
topology = UDS.new(width, height, 20)

# some initial set of tags. this could be empty, and can be changed over time. 
tags = ["events", "system", "reviews", "happy", "blah", "animals"]
# parameter to determine length of hashIDs in LMS
lambda_ = 256
# LMS parameter
hops = 2
# network parameter
num_nodes = 800

#universe = God.new(topology)
universe = God.new(topology, hops)

(1..num_nodes).each{|id|
  x = rand(width)
  y = rand(height)
  subscription = tags[rand(tags.length)] 
  fog_node = FogNode.new(id, routing=LMS, lambda_=256, hops=2, buffer_size = rand(20), max_failures = 5, x, y, subscription)
  universe.add(fog_node)
}

n1 = universe.getNode(1)
n2 = universe.getNode(2)
n3 = universe.getNode(3)
newguy = FogNode.new(1000, routing=LMS, lambda_, hops, buffer_size = rand(20), max_failures = 5, x=75, y = 75)
universe.add(newguy)
universe.updateAllNeighbors()

n1.publish(tag = "haiku", message = "<--START-->", lifetime = 20, radius = 500, replicas = 10)
n1.publish(tag = "haiku", message = "alice’s plaintext", lifetime = 20, radius = 500, replicas = 10)
n2.publish(tag = "haiku", message = "proxy and delegatee", lifetime = 20, radius = 500, replicas = 10)
n3.publish(tag = "haiku", message = "fear for collusion", lifetime = 20, radius = 500, replicas = 10)
n3.publish(tag = "haiku", message = "<--END-->", lifetime = 20, radius = 90, replicas = 10)
n2.publish(tag = "news", message = "I LOVE FOG", lifetime = 20, radius = 500, replicas = 10)
n2.publish(tag = "news", message = "Poor bobby.. no alien life", lifetime = 20, radius = 500, replicas = 10)
n2.publish(tag = "news", message = "I'm running out of things to say for test cases", lifetime = 20, radius = 500, replicas = 10)
n2.publish(tag = "news", message = "life sucks", lifetime = 20, radius = 500, replicas = 10)

puts "\nN2"
puts n2.query("haiku")
puts "\nNEWGUY"
puts newguy.query("haiku")
puts "\nN3"
puts n3.query("haiku")
universe.remove(n3.realID) #remove publishing nodes, just to show that the messages are in the network
universe.remove(n2.realID)
universe.remove(n1.realID)
universe.updateAllNeighbors()
puts "\nNEWGUY -- BEFORE SUBSCRIPTIONS"
puts newguy.check()
puts "\nNEWGUY -- AFTER SUBSCRIPTIONS"
newguy.addSubscription("haiku")
pp newguy.check()

n4 = universe.getNode(4)

n4.publish(tag = "haiku", message = "awesome", lifetime = 20, radius = 500, replicas = 10)
n4.publish(tag = "haiku", message = "yay", lifetime = 20, radius = 500, replicas = 10)

pp newguy.check()
pp newguy.cached()

newguy.addSubscription("news")
pp newguy.check()
pp newguy.cached()


