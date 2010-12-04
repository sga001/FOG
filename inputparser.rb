require 'rexml/document'

=begin
  How to use: input = InputParser.new("fileNameHere")
              input.parse( pass in god and then you can proxy calls through god )
=end

class InputParser
  def initialize(fileName)
    @doc = REXML::Document.new(File.new(fileName))
  end
  
  def getDocument()
    return @doc
  end
  
  def parser(god = nil)
    @doc.elements.each{ |commands|
      commands.elements.each{|element|
        name = element.name
          if name == "addNode"
            id = element.attributes["id"]
            x = element.attributes["x"]
            y = element.attributes["y"]
            buffer = element.attributes["buffer"]
            puts "process addNode with id = " + id  + " x= " + x + " y= " + y + " buffer= " + buffer
                     
          elsif name == "deleteNode"
            id = element.attributes["id"]
            puts "process deleteNod with id = " + id
          
          elsif name == "addTag"
            tag = element.attributes["name"]
            puts "process addTag with name = " + tag
            
          elsif name == "deleteTag"
            tag = element.attributes["name"]
            puts "process deleteTag with name = " + tag
          
          elsif name == "move"
            node =  element.elements["Node"]
            id = node.attributes["id"]
            dx = element.attributes["dx"]
            dy = element.attributes["dy"]
            puts "process move to node id =" + id + ", by dx = " + dx + ", and dy = " + dy
          
          elsif name == "subscribe"
            node =  element.elements["Node"]
            tag = element.elements["Tag"]
            id = node.attributes["id"]
            tagName = tag.attributes["name"]
            puts "process subscribe to node id = " + id + ", to tag = " + tagName 
            
          elsif name == "unsubscribe"
            node =  element.elements["Node"]
            tag = element.elements["Tag"]
            id = node.attributes["id"]
            tagName = tag.attributes["name"]
            puts "process unsubscribe to node id = " + id + ", from tag = " + tagName 

          elsif name == "publish"
            node =  element.elements["Node"]
            tag = element.elements["Tag"]
            id = node.attributes["id"]
            tagName = tag.attributes["name"]
            message = element.attributes["message"]
            puts "process publish using node id = " + id + ", and tag = " + tagName + ", and message = " + message 
          end
      }
    }
  end
end