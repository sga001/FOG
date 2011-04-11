# tests of node behaviour with LMS installed

require 'test/unit'
require '../mixins.rb'
require '../lms.rb'
require '../node.rb'

LMS.setup(hops=1, lambda_=256, max_failures=5, randWalkRange=10, randWalkMin=5)
class Node
	include LMS
end

class NodeWithLMSTests < Test::Unit::TestCase

	def test_inst_var
		n = Node.new
		assert_not_nil(n.hashID)
	end

	def test_lms_node_class_vars
		observed = Node.class_variables
		expected = ["@@id", "@@hops","@@max_failures","@@randomWalkRange", "@@randomWalkMin", "@@lambda", "@@hash_functions"]
		assert_equal([], observed-expected)
	end
end	

