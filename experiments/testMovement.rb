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
hops = 1
radius = 200
num_nodes = 500
num_puts = 100
num_gets = 100
# -------------------------------------------------
# -------------------------------------------------

# experiments where we vary the number of nodes, hops, and
# braodcast radius.
log = File.open("log-#{DateTime.now.to_s}", 'w')
log.write("Node, time, position \n")
log.flush()

topology = UDS.new(world_width, world_height, radius)
universe = God.new(topology)
universe.setNodeSettings(lambda_, max_failures, hops, update_frequency = 100, type=FogNode, routing=LMS, buffer_size=1000)
  	#Add 100 nodes with 100% probability, 0% probability of moving and 0% probability of dropping
  	(0..num_nodes).each{
		universe.step(join=1000, drop=0, move=0)
	}
	
	nid = rand(num_nodes)
	(0..1000).each{|n|
		node = universe.getNode(nid)
		if node == nil
			break
		end
		log.write("#{nid}, #{universe.getTime()}, #{node.x},#{node.y}\n")
		universe.step()
		if n % 200 == 0
			log.flush()
		end
	}
	log.flush()
=begin	  
	put_recall_sum = 0.0
	stored = []
	# do 100 puts of the same tag and message

	(1..num_puts).each {|m|
		key = rand.hash.to_s
		node_id = rand(universe.maxID())
		node = universe.getNode(node_id)
		while node == nil do
			node_id = rand(num_nodes)
			node = universe.getNode(node_id)
	    end
        recall, stats = node.routing.put(tag = key, message = "djksjaljd", replicas)
        put_recall_sum += recall
        stored.push(key) unless recall == 0
        universe.step()
	}
	put_recall_avg = put_recall_sum/num_puts
	get_recall_sum = 0.0
	# do 100 gets of the same tag and message
	(1..num_gets).each {
     	 key = stored[rand(stored.length)]
         node_id = rand(num_nodes)
         node = universe.getNode(node_id)
         while node == nil do
         	node_id = rand(num_nodes)
         	node = universe.getNode(node_id)
         end
         item, recall = node.routing.managedGet(key) 
         get_recall_sum += recall
         universe.step()
	}
    get_recall_avg = get_recall_sum/num_gets
	log.write("1, #{hops}, #{num_nodes}, #{radius}, #{put_recall_avg}, #{get_recall_avg}, #{universe.getTime()}\n")
	log.flush()
=end

