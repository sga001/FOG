require 'uds.rb'
require 'lms.rb'
require 'pp'

module FogApp
=begin
	publish, subscribe and fog application layer stuff
=end

  def publish(tag, message, lifetime, radius, replicas)
    # calls the PUT method of the routing layer. lifetime specifies a lifetime
    # for the message in seconds. radius specifies a radius of applicability--
    # nodes outside this radius from the message will not see it. (this is a
    # hack right now-- it is still stored just not retuned if the radius is
    # exceeded. also, it should be a radius from the originator not the replica
    # host XXX TODO). 
    value = FogDataObject.new(initiator = @nid, message, lifetime, radius)
    @routing.put(tag, value, replicas)
  end
  
  def query(tag)
    # issues 20 LMS GET probes. the number 20 should be dynamic; probes should
    # happen in parallel. 
    message_list =  []
    (1...20).each{
      fog_items, probe = @routing.get(tag)
      if fog_items
        fog_items.each{|item| 
        if @cached_messages.key?(tag)
          l = @cached_messages[tag]
          if not l.include?(item.message)
            message_list.push(item.message)
          end
        else
          message_list.push(item.message)
        end 
       }
       end
    }
    
    return message_list.uniq
  end
  
  def cache_messages()
    @new_messages.each{|tag, list|
      l = []
      if(@cached_messages.key?(tag))
        l = @cached_messages[tag]
      end
      l+= list
      @cached_messages.store(tag, l)
    }
    @new_messages = {}
  end

  def check()
    @subscriptions.each{|tag|
      @new_messages.store(tag, query(tag))
    }
    list = @new_messages
    cache_messages()

    return list
  end

  def cached()
    return @cached_messages
  end
  def remind() #is this really necessary
    # remind your neighbours of the messages you have by issuing a digest to
    # them. 
  end

  def addSubscription(tag)
    @subscriptions.push(tag) if not @subscriptions.include?(tag)
  end 

  def deleteSubscription(tag)
    @subscriptions.delete(tag)
  end

 
end

=begin
  This class represents a Fog Data Object which is composed of: Initiator,
  Message, Lifetime, and Radius
=end
class FogDataObject
  def initialize(initiator, message, lifetime, radius)
    @initiator, @message, @radius = initiator, message, radius
    @created = Time.now
    @expiry = Time.now + lifetime
  end
  
  def message
    return @message
  end
  
  def expiry
    return @expiry
  end
  
  def radius
    return @radius
  end
end


