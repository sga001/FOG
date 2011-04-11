#!/usr/bin/ruby

require 'fogpubsub.rb'
require 'uds.rb'
require 'lms.rb'
require 'date'


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

num_messages = 10

# -------------------------------------------------
# -------------------------------------------------

# experiments where we vary the number of nodes, hops, and
# braodcast radius.

log = File.open("log-#{DateTime.now.to_s}", 'w')
log.write("Experiment,hops,nodes,broadcast,put recall, get recall\n")
log.flush()
i = 0
results = []
(2..5).each { |hops|
    (50..700).step(50).each{ |broadcast_radius|
        topology = UDS.new(world_width, world_height, broadcast_radius)
        universe = God.new(topology)
        # for num_nodes we use the smallest numbers of nodes for which 
        # performance was still maxed out in our earlier experiments.  
        num_nodes = 500 

        puts "-------------------------------------------------------------------------------------"
        puts "Experiment: #{hops} hops, broadcast radius = #{broadcast_radius}."
        puts "-------------------------------------------------------------------------------------"

        # initialize nodes 
        (0..num_nodes-1).each{|id|
            x = rand(world_width)
            y = rand(world_height)
            fog_node = FogNode.new(id, routing=LMS, lambda_, hops, 
                        buffer_size = 1000, max_failures, x, y)
            universe.add(fog_node)
        }
        # this function call makes use of the location of nearby nodes so
        # we can just save the neighbour determination for after all nodes
        # have been added. 
        puts "determining node neighbours..."
        universe.updateAllNeighbors()
        puts "... done."

        # put and get num_messages and average the quality of the results
        put_recall_sum = 0.0
        stored = []
        (1..num_messages).each {|m|
            print "#{m}, "
            STDOUT.flush
            key = rand.hash.to_s
            node_id = rand(num_nodes)
            node = universe.getNode(node_id)
            recall, stats = node.routing.put(tag = key, message = "djksjaljd", replicas)
            put_recall_sum += recall
            # only add a key to the list of stored items if it didn't completely fail.
            stored.push(key) unless recall == 0
        }
        puts ""
        put_recall_avg = put_recall_sum/num_messages
        puts "Put recall (avg/#{num_messages}) #{put_recall_avg}"

        # query for each of the items - 'managed' get will repeat the get
        # request until it succeeds or some max threshold is hit. 
        get_recall_sum = 0.0
        (1..num_messages).each {|m|
            print "#{m}, "
            STDOUT.flush
            key = stored[rand(stored.length)]
            node_id = rand(num_nodes)
            node = universe.getNode(node_id)
            item, recall = node.routing.managedGet(key) 
            get_recall_sum += recall
        }
        puts "\n\n"
        get_recall_avg = get_recall_sum/num_messages
        puts "Put recall (avg/#{num_messages}) #{put_recall_avg}"
        puts "Get recall (avg/#{num_messages}) #{get_recall_avg}"

        results[i] = {'nodes' => num_nodes, 'hops' => hops, 
                        'broadcast_radius' => broadcast_radius,
                        'put_recall' => put_recall_avg,
                        'get_recall' => get_recall_avg }

        
        log.write("#{i},#{hops},#{num_nodes},#{broadcast_radius},#{put_recall_avg}, #{get_recall_avg}\n")
        log.flush()
        i += 1

        puts "-------------------------------------------------------------------------------------"
        puts "\n"

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
