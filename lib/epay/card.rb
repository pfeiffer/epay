module Epay
  class Card
    attr_accessor :exp_month, :exp_year, :kind, :number
    
    def initialize(attributes = {})
      attributes.each do |name, value|
        self.send("#{name}=", value) if respond_to?("#{name}=")
      end
    end
    
    def expires_at
      Date.new(2000 + exp_year, exp_month, 1).end_of_month
    end
    
    def hash
      [number, exp_year, exp_month].join("") if number.present?
    end
    
    def last_digits
      number[-4, 4] if number.present?
    end
  end
end