require 'bitfield.rb'
require 'digest/sha1'
class BloomFilter

=begin
  Initializes the Bloomfilter to size bits, and k hash functions
=end

  def initialize(size, k)
    @size, @k = size, k
    @field = BitField.new(size)
  end

# Insert an element into the bitfield
  def insert(key)
    (1..@k).each{|n|
      d = Digest::SHA1.hexdigest(n.to_s+key).hex
      h = d.modulo(@size)
      @field[h] = 1
   }
  end
 
# Check the element in the bitfield
  def include?(key)
    flag = true
    (1..@k).each{|n|
      d = Digest::SHA1.hexdigest(n.to_s+key).hex
      h = d.modulo(@size)
      if @field[h] != 1
        flag = false
      end
    }
    return flag
  end
    
 def digest()
   return @field
 end
end
