require 'bloomfilter.rb'
require 'pp'

=begin
	Basic Node functionality
=end

class Node

	# create a global id namespace for convenience tracking. might be
	# problematic if we have a TON of nodes, and note that IDs from nodes that
	# get killed never get re-used. 
	@@id = 0

	def initialize(x, y)
		@nid = @@id
		@@id += 1
		@x = x
		@y = y
		@max_buffer = rand(20) +10
		@current_buffer = 0
		@buffer = {}
		@digest = BloomFilter.new(512, 10) # 512 bits, 10 hash functions
		@neighbors = [] #-> FogNodes

		# not exactly sure what we use these for.. something to do with
		# subscriptions instead of LMS items?
		@new_messages = {}
		@cached_messages = {}

		# deprecated... for now. 
		#@routing = routing.new(self, hops, lambda_, max_failures) 
		#@speed = speed
	end
	attr_accessor :nid, :x, :y, :neighbors

    #these are the 1 hop neighbors... they are FogNodes!!!  
	def updateNeighbors (list)
		# the neighbors being passed in are physical neihgbors. neighbors in the
		# routing overlay may be different.  
		@neighbors = list
	end

	def to_s
		return "[" + @x.to_s + "," + @y.to_s + "]"
	end

	# Physical Storage Methods
   
	def bufferAdd(k, item)
		# add the item if new or update the item if that key already exists in the
		# buffer
		unless bufferFull?
			if containsKey?(k)
				list = @buffer[k]
				list.push(item)
				@buffer.store(k, list)
			else
				list = []
				list.push(item)
				@buffer.store(k, list)
				@digest.insert(k)
			end
			@current_buffer += 1 
		else
			raise "Max buffer size exceeded"
		end
	end

	def containsKey?(k)
		return @buffer.key?(k)
	end

	def containsData?(item)
		@buffer.each{|key, value|
			value.each{|data|
				if data == item
					return true
				end
			}
		}
		return false
	end

	def bufferFull?
		if @current_buffer >= @max_buffer
			return true
		else
			return false
		end
	end

	def bufferLength()
		return @current_buffer
	end

	def retrieve(k)
		return @buffer[k]
	end

	def digest()
		return @digest
	end

end


