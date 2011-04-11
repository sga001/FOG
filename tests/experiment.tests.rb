
require 'test/unit'
require '../mixins.rb'
require '../lms.rb'
require '../node.rb'


LMS.setup(hops=1, lambda_=256, max_failures=5, randWalkRange=10, randWalkMin=5)
# install the modules we just set up
Comms.setup(sim)
Node.setup(broadcastRange=1, broadcastMin=10, bufferRange=10, bufferMin=20)
class Node
	include Comms
	include LMS
end

class SimulatorTests < Test::Unit::TestCase
	def setup
		@sim = Simulator.new
		@sim.include LMSEvents
		UDSTopology.setup(width=100, height=100)
		@sim.include UDSTopology
	end

	def test_add_node
		start_time = @sim.time
		@sim.addNodes(1)
		end_time = @sim.time
		assert(end_time == start_time + 1)
	end

	def test_node_comms
		n = Node.new
		assert(true, n.class.class_variables.include? "@@sim")
		n.class.class_eval {
			@@sim.instance_of? Simulator
		}
	end

	def test_node_get_neighbors
		# add two nodes at explicit locations and check that their neighbor
		# relationship is as expected based on the broadcast radius, hops, etc. 
		@sim.addNodeAtLocation(10,10)
		@sim.addNodeAtLocation(10,10)
		@sim.addNodeAtLocation(10,10)


	end

	def test_distance
		# add two nodes at explicit locations and check that their distance is
		# what we expect it to be. 
		n1 = sim.addNodeAtLocation(10,10)
		n2 = sim.addNodeAtLocation(19,10)
		assert_equal(distance(n1,n2), 3)
	end


	def test_node_movement
		# check to see that a single step movement is within the radius
		# expected.
	end

	def test_occupied
	end

	def test_remove_node
	end

	def test_advance_state
	end



sim.event('addNodes', 1000)
