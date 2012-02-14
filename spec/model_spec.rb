require 'spec_helper'

module Epay
  class MockedModel
    include Model

    def self.inspectable_attributes
      %w(id description another_attribute)
    end
    
    def description
      'Description'
    end
    
    def another_attribute
      'Another'
    end
  end
  
  describe 'Model' do
    let(:model) do
      MockedModel.new(42)
    end
    
    describe "inspection" do
      it "contains id" do
        model.inspect.to_s.should =~ /id: 42/
      end
      
      it "contains attributes" do
        model.inspect.to_s.should =~ /description: "Description"/
        model.inspect.to_s.should =~ /another_attribute: "Another"/
      end
    end
  end
end