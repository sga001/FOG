require 'digest/sha1'

# an demo to explore the key space and local minima
log = File.open("nodespace-#{DateTime.now.to_s}", 'w')
log.write("node,key,x,y\n")
log.flush()

world_height = 1000
world_width = 1000
lambda_ = 256

nodes = []
(100...3000).each{ |num_nodes|
    # initialize nodes 
    (0..num_nodes-1).each{|id|
        x = rand(world_width)
        y = rand(world_height)
        key = Digest::SHA1.hexdigest(id.to_s).hex.modulo(2**lambda_)
        
        log.write("#{id},#{key},#{x},#{y,}")
        log.flush()
    }
}

# get a random key and compute the number of local minima
msg_key = rand.hash.to_s

# choose a random point and look in the h-hop neighbourhood. 

