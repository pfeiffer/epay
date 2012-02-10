module Epay
  module Model
    attr_accessor :id, :data
    
    def initialize(id, data = {})
      @id = id
      @data = data
    end
    
    def inspect
      inspection = self.class.inspectable_attributes.collect do |name|
        #"#{name}: #{selfsend(name)}"
        "#{name}: #{send(name).inspect}" if respond_to?(name)
      end.join(", ")
      
      "#<#{self.class} #{inspection}>"
    end
    
    def self.inspect
      "inspect via class"
    end
  end 
end