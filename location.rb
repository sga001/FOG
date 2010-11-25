# This class probably has to change depending on whether we want 2d or 3d, and how distance should be calculated.
class Location 
    def initialize(x, y)
      @x, @y = x, y
    end
  
    def distance(loc2)
      Math.sqrt(((@x-loc2.getX())**2) + ((@y - loc2.getY())**2))
    end
    
    def getX()
     return @x
    end
    
    def getY()
     return @y
    end
    
    def to_s()
     return "[" + @x.to_s + "," + @y.to_s + "]"
    end
end