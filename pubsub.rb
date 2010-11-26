require 'uds.rb'

=begin
A publish/subscribe mechanism. Runs on each node in the network. 
=end

class PubSub

  def initialize(nodes, routing_layer, physical_layer)
  end 

  def publish
    
  end

  def subscribe
    
  end

end

participants = 100

ps = PubSub(participants, routing='lms', physical='uds')

