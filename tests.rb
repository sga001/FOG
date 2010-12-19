#!/usr/bin/ruby

require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'
require 'pp'

# -------------------------------------------------
#           LMS layer experiments
# -------------------------------------------------
# GLOBAL PARAMS - do not change across experiments
# -------------------------------------------------

max_failures = 5

# how many replicas to store. should be adaptive but isn't ;)
replicas = 10

# LMS hashID parameter
lambda_ = 256

# think of these as meters. 
world_width = 1000
world_height = 1000

# -------------------------------------------------
# -------------------------------------------------

# experiments where we vary the number of nodes, hops, and
# braodcast radius.
(1..2).each { |hops|
    [100,200,300].each{ |broadcast_radius|
        topology = UDS.new(world_width, world_height, broadcast_radius)
        universe = God.new(topology)
        (10..1000).step(10).each { |num_nodes| 

            # initialize nodes in the universe with randomized subscriptions
            # and a random buffer size between 1 and 20
            (1..num_nodes).each{|id|
                x = rand(world_width)
                y = rand(world_height)
                fog_node = FogNode.new(id, routing=LMS, lambda_, hops, 
                            buffer_size = rand(20), max_failures, x, y)
                universe.add(fog_node)
            }

            # pick off some nodes to demonstrate put and get operations with 
            n1 = universe.getNode(1)
            n2 = universe.getNode(2)
            n3 = universe.getNode(3)

            # place ten messages into the system. why 10? does one put
            # operation interact with others? only if we are exploring backoff
            # behaviour, but since we have the system set up we might as well
            # put a bunch of messages out there. 
            n1.routing.put(tag = "t1", message = "n1 publishes with tag t1", replicas)
            n2.routing.put(tag = "t2", message = "n2 publishes with tag t2", replicas)
            n3.routing.put(tag = "t3", message = "n3 publishes with tag t3", replicas)
            n1.routing.put(tag = "t4", message = "n1 publishes with tag t4", replicas)
            n2.routing.put(tag = "t5", message = "n2 publishes with tag t5", replicas)
            n3.routing.put(tag = "t6", message = "n3 publishes with tag t6", replicas)
            n1.routing.put(tag = "t7", message = "n1 publishes with tag t7", replicas)
            n2.routing.put(tag = "t8", message = "n2 publishes with tag t8", replicas)
            n3.routing.put(tag = "t9", message = "n3 publishes with tag t9", replicas)
            n1.routing.put(tag = "t10", message = "n1 publishes with tag t10", replicas)

            # get some new nodes and do some querying
            n4 = universe.getNode(4)
            n5 = universe.getNode(5)
            n6 = universe.getNode(6)

            # query for each of the items - 'managed' get will repeat the get
            # request until it succeeds or some max threshold is hit. 
            n4.routing.managedGet("t0") 
            n5.routing.managedGet("t2")
            n6.routing.managedGet("t3")
            n4.routing.managedGet("t4") 
            n5.routing.managedGet("t5")
            n6.routing.managedGet("t6")
            n4.routing.managedGet("t7") 
            n5.routing.managedGet("t8")
            n6.routing.managedGet("t9")
            n4.routing.managedGet("t10") 
            
            exit!

        }
    }   
}

exit!

# other things you can do

=begin
# newguy = FogNode.new(1000, routing=LMS, lambda_, hops, buffer_size = rand(20), max_failures = 5, x=75, y = 75)
# universe.add(newguy)
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

=end
