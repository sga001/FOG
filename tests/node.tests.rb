# test cases for stuff

require 'test/unit'
require 'mixins.rb'
require 'lms.rb'
require 'node.rb'

class RubySimTests < Test::Unit::TestCase
	def setup
	end

	def teardown
	end

	def test_node
		n1 = Node.new
		n2 = Node.new
		assert_equal(n2.nid, n1.nid+1)
	end

	def test_buffer_full
		n1 = Node.new
		buffer_size = n1.instance_variable_get(:@max_buffer)
		items_stored = 0
		while items_stored < buffer_size do
			n1.bufferAdd('key', 'blah')
			items_stored += 1
		end
		assert(n1.bufferFull?)

	end
end

