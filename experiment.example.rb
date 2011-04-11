require 'node.rb'
require 'lms.rb'
require 'mixins.rb'

######### SETUP ##########

sim = Simulator.new
sim.include LMSEvents
# by including the UDSTopology module we build several new methods and instance
# variables into the simulator.
UDSTopology.setup(width, height)
sim.include UDSTopology

# initialize global parameters for LMS
LMS.setup(hops=1, lambda_=256, max_failures=5, randWalkRange=10, randWalkMin=5)
# initialize the comms channel to the simulator we'll be using
Comms.setup(sim)

# install the modules we just set up
class Node
	include Comms
	include LMS
end 

######### RUN ##########

sim.event('addNodes', 1000)
sim.event('advanceState', numAdd=10, numKill=20, percentMove=50)
sim.event('LMSput', 'events', 'the bon jovi concert was good', 50)


