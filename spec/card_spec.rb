require 'spec_helper'

module Epay
  describe Card do
    let(:card) do
      Card.new(:number => '333333XXXXXX3000', :exp_year => 15, :exp_month => 10, :kind => :visa)
    end
    
    it "generates a hash" do
      card.hash.should == '333333XXXXXX30001510'
    end
    
    it "has expires_at" do
      card.expires_at.should == Date.new(2015, 10, 31)
    end
    
    it "has last_digits" do
      card.last_digits.should == '3000'
    end
  end
end